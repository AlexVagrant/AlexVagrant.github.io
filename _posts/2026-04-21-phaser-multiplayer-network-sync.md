---
layout: post
title: "Phaser 多人游戏网络同步：频率、插值与平滑过渡"
date: 2026-04-21
category:
tags: [Phaser, Game Development, Network Sync, Multiplayer]
---

在多人网络游戏中，玩家角色的平滑移动是最基础也最复杂的挑战之一。由于网络延迟、抖动和丢包，服务器发来的位置数据总是离散的、延迟的。如果直接渲染接收到的坐标，会出现严重的"抖动"和"跳跃"现象。本文从零开始，探讨如何设计与实现一套完整的客户端运动同步系统。

<!-- more -->

## 一、IM 上下行数据结构

### 1.1 上行：客户端上报自身移动

客户端主动将本地玩家位置上报给服务器，用于广播给其他客户端。

```typescript
// V1 协议（简单路径，无时间戳）
interface IUserMoveUpMessageV1 {
  moveList: Array<{ x: number, y: number }>
}

// V2 协议（带序列号和时间戳，支持精确插值）
interface IMovePointV2 {
  x: number
  y: number
  offsetMs: number  // 相对于起始点的时间偏移（毫秒）
}

interface IMoveInfoV2 {
  version: 2
  seq: number       // 序列号，用于去重和排序
  durationMs: number // 路径总时长
}

interface IUserMoveUpMessageV2 {
  moveList: IMovePointV2[]
  moveInfo: IMoveInfoV2
}
```

### 1.2 下行：服务器广播其他玩家移动

服务器以固定频率（通常 10-20Hz）将所有在线玩家的移动信息广播给相关客户端。

```typescript
// V1 协议
interface IMoveLocation {
  x: number
  y: number
}

interface IUserMoveDownMessageV1 {
  momoId: string
  game: string
  moveList: IMoveLocation[]
}

// V2 协议（带时间戳，支持精确重建运动轨迹）
interface IMoveLocationV2 {
  x: number
  y: number
  offsetMs: number  // 相对于当前包的时间偏移
}

interface IUserMoveDownMessageV2 {
  momoId: string
  game: string
  moveList: IMoveLocationV2[]
  moveInfo: IMoveInfoV2
  t?: number         // 服务器时间戳（可选）
}
```

### 1.3 协议版本判别与规范化

由于服务器可能同时支持 V1 和 V2 协议，客户端需要对接收到的数据进行规范化处理：

```typescript
// moveProtocol.ts
function isTimedMoveList(moveList: IMoveLocation[]): moveList is IMoveLocationV2[] {
  return moveList.every(point => typeof (point as IMoveLocationV2).offsetMs === 'number')
}

function isMoveInfoV2(moveInfo: unknown): moveInfo is IMoveInfoV2 {
  const candidate = moveInfo as Partial<IMoveInfoV2>
  return candidate?.version === 2
    && typeof candidate.seq === 'number'
    && typeof candidate.durationMs === 'number'
}

// 规范化：将所有输入转为统一的内部格式
interface INormalizedMovePoint {
  x: number
  y: number
  offsetMs: number
}

interface INormalizedUserMoveMessage {
  momoId: string
  game: string
  moveList: INormalizedMovePoint[]
  moveInfo: {
    version: 1 | 2
    seq: number | null
    durationMs: number
  }
  eventTimeMs: number | null
}

function normalizeUserMoveDownMessage(msg: IUserMoveDownMessage): INormalizedUserMoveMessage {
  const moveInfo = isMoveInfoV2((msg as IUserMoveDownMessageV2).moveInfo)
    ? (msg as IUserMoveDownMessageV2).moveInfo
    : null

  const normalizedMoveInfo = moveInfo
    ? { version: 2, seq: moveInfo.seq, durationMs: moveInfo.durationMs }
    : { version: 1, seq: null, durationMs: 1000 }  // V1 默认 1 秒

  // 如果是 V2 且路径点包含时间戳，直接使用；否则平均分配时间
  const moveList = moveInfo && isTimedMoveList(msg.moveList)
    ? msg.moveList.map(point => ({ x: point.x, y: point.y, offsetMs: point.offsetMs }))
    : estimateMoveOffsets(msg.moveList, normalizedMoveInfo.durationMs)

  return {
    momoId: msg.momoId,
    game: msg.game,
    moveList,
    moveInfo: normalizedMoveInfo,
    eventTimeMs: 't' in msg ? (msg as IUserMoveDownMessageV2).t : null
  }
}
```

### 1.4 数据去重

V2 协议通过 `seq` 序列号实现消息去重：

```typescript
function isMoveMessageStale(
  msg: Pick<INormalizedUserMoveMessage, 'moveInfo'>,
  lastSeq: number | null
): boolean {
  if (msg.moveInfo.version !== 2 || msg.moveInfo.seq === null || lastSeq === null) {
    return false
  }
  return msg.moveInfo.seq <= lastSeq
}
```

## 二、客户端运动状态机设计

### 2.1 核心状态结构

```typescript
interface IMotionSegment {
  start: { x: number, y: number }
  end: { x: number, y: number }
  startTimeMs: number
  endTimeMs: number
}

interface IScheduledMotionPath {
  endPoint: { x: number, y: number }
  endTimeMs: number
  segments: IMotionSegment[]
}

interface IBufferedMotionSnapshot {
  point: { x: number, y: number }
  timeMs: number
}

interface IOtherPlayerMotionState {
  // 当前渲染位置（屏幕上的真实坐标）
  renderPosition: { x: number, y: number }

  // 已收到的最新服务器时间
  lastSampleTimeMs: number

  // 运动结束时间（用于判断"静止"状态）
  lastMotionEndTimeMs: number | null

  // 快照缓冲（用于插值的已接收位置历史）
  snapshots: IBufferedMotionSnapshot[]

  // 预排路径（用于精确播放已知路径）
  activeReplayPath: IScheduledMotionPath | null
  bufferedReplayPaths: IScheduledMotionPath[]

  // 是否有待播放的运动
  hasPendingMotion: boolean
}
```

### 2.2 状态机分层

```
┌─────────────────────────────────────────────────────┐
│                 运动状态机分层                        │
├─────────────────────────────────────────────────────┤
│  Replay Path Layer (优先级高)                        │
│  - 场景：服务器下发 V2 协议路径（带时间戳）            │
│  - 行为：按预定时间表精确播放，不依赖网络实时数据      │
├─────────────────────────────────────────────────────┤
│  Snapshot Interpolation Layer (降级方案)             │
│  - 场景：V1 协议或 V2 但时间戳无效                    │
│  - 行为：通过插值重建"已知的过去"，外推"未知的未来"    │
└─────────────────────────────────────────────────────┘
```

## 三、Replay Path：精确播放已知路径

当服务器下发 V2 协议数据时（包含 `offsetMs` 时间戳），我们可以精确重建完整的运动时间表，不依赖后续网络数据。

### 3.1 构建时间驱动的路径

```typescript
function buildTimedScheduledMotionPath(
  anchorPoint: { x: number, y: number },
  points: INormalizedMovePoint[],
  scheduledStartTimeMs: number,
  durationMs?: number,
): IScheduledMotionPath | null {
  if (points.length === 0) return null

  // 如果第一个点的时间偏移大于 0，补充锚点
  let timelinePoints = points.map(point => ({
    x: point.x,
    y: point.y,
    offsetMs: point.offsetMs
  }))

  if (timelinePoints[0].offsetMs > 0) {
    timelinePoints = [{ x: anchorPoint.x, y: anchorPoint.y, offsetMs: 0 }, ...timelinePoints]
  }

  // 构建线段
  const segments: IMotionSegment[] = []

  for (let index = 1; index < timelinePoints.length; index++) {
    const start = timelinePoints[index - 1]
    const end = timelinePoints[index]
    const segmentDurationMs = end.offsetMs - start.offsetMs

    // 时间倒退或零时长位移都是无效的
    if (segmentDurationMs < 0) return null
    if (segmentDurationMs === 0 && (start.x !== end.x || start.y !== end.y)) return null

    segments.push({
      start: { x: start.x, y: start.y },
      end: { x: end.x, y: end.y },
      startTimeMs: scheduledStartTimeMs + start.offsetMs,
      endTimeMs: scheduledStartTimeMs + end.offsetMs
    })
  }

  if (segments.length === 0) return null

  return {
    endPoint: { x: segments[segments.length - 1].end.x, y: segments[segments.length - 1].end.y },
    endTimeMs: segments[segments.length - 1].endTimeMs,
    segments
  }
}
```

### 3.2 采样 Replay Path

```typescript
function sampleReplayPath(
  state: IOtherPlayerMotionState,
  nowMs: number,
): { position: { x: number, y: number }, isMoving: boolean, hasPendingMotion: boolean } | null {
  // 弹出下一个排队的路径
  promoteBufferedReplayPath(state)

  // 如果当前路径已播放完，检查是否有缓冲路径
  while (state.activeReplayPath && nowMs >= state.activeReplayPath.endTimeMs) {
    state.lastMotionEndTimeMs = state.activeReplayPath.endTimeMs
    state.renderPosition = { x: state.activeReplayPath.endPoint.x, y: state.activeReplayPath.endPoint.y }
    state.activeReplayPath = null
    promoteBufferedReplayPath(state)
  }

  if (!state.activeReplayPath) return null

  // 如果当前时间还未到路径开始，停在锚点
  if (nowMs < state.activeReplayPath.segments[0].startTimeMs) {
    return {
      position: { x: state.renderPosition.x, y: state.renderPosition.y },
      isMoving: false,
      hasPendingMotion: true
    }
  }

  // 找到当前时间所在的线段
  const activeSegment = state.activeReplayPath.segments.find(
    segment => nowMs <= segment.endTimeMs
  ) || state.activeReplayPath.segments[state.activeReplayPath.segments.length - 1]

  // 在线段内插值
  const position = interpolateSegment(activeSegment, nowMs)
  const isMoving = (activeSegment.start.x !== activeSegment.end.x || activeSegment.start.y !== activeSegment.end.y)
    && nowMs < activeSegment.endTimeMs

  return {
    position,
    isMoving,
    hasPendingMotion: true
  }
}

function promoteBufferedReplayPath(state: IOtherPlayerMotionState): void {
  if (!state.activeReplayPath && state.bufferedReplayPaths.length > 0) {
    state.activeReplayPath = state.bufferedReplayPaths.shift() || null
  }
}
```

### 3.3 路径队列

多个路径可以排队执行，用于处理玩家在短时间内发出多个移动指令的场景：

```typescript
function enqueuePath(state: IOtherPlayerMotionState, path: IScheduledMotionPath): void {
  if (!state.activeReplayPath) {
    state.activeReplayPath = path
  } else {
    state.bufferedReplayPaths.push(path)  // 排队等待
  }
}
```

## 四、Snapshot 插值：降级方案

当服务器下发的是 V1 协议（无时间戳），或者 V2 但时间戳无效时，我们无法精确重建时间表，只能依赖快照插值。

### 4.1 延迟缓冲策略

插值的核心思想：**不要渲染"现在"的位置，而是渲染"稍早"的位置**。

```typescript
// 渲染时间 = 当前时间 - 插值延迟
const renderTimeMs = nowMs - config.interpolationDelayMs
```

假设 `interpolationDelayMs = 150ms`，那么我们在"150ms 前"的时间点上进行插值。这意味着我们总是有"缓冲窗口"来填充缺失的中间帧。

为什么需要延迟？如果没有延迟，我们可能刚收到一个包，下一个包 200ms 后才到，中间就无数据可渲染。延迟缓冲让我们有足够时间等待下一个包的到来。

### 4.2 线性插值

```typescript
function interpolateSegment(
  segment: IMotionSegment,
  nowMs: number
): { x: number, y: number } {
  const durationMs = segment.endTimeMs - segment.startTimeMs
  if (durationMs <= 0) {
    return { x: segment.end.x, y: segment.end.y }
  }

  const progress = Math.min(Math.max((nowMs - segment.startTimeMs) / durationMs, 0), 1)
  return {
    x: segment.start.x + (segment.end.x - segment.start.x) * progress,
    y: segment.start.y + (segment.end.y - segment.start.y) * progress,
  }
}
```

### 4.3 快照采样

```typescript
interface MotionConfig {
  interpolationDelayMs: number      // 插值延迟，通常 100-200ms
  maxExtrapolationMs: number        // 外推上限，通常 100-200ms
  snapshotRetentionMs: number       // 快照保留时间，通常 500-1000ms
  speedPxPerSecond: number          // 速度（像素/秒）
}

function sampleSnapshotsWithBuffer(
  state: IOtherPlayerMotionState,
  nowMs: number,
  config: MotionConfig
): ISampledMotionState {
  if (state.snapshots.length === 0) {
    return {
      position: { x: state.renderPosition.x, y: state.renderPosition.y },
      isMoving: false,
      hasPendingMotion: false
    }
  }

  const renderTimeMs = nowMs - config.interpolationDelayMs

  // 清理过期的快照
  pruneSnapshots(state, renderTimeMs, config.snapshotRetentionMs)

  const firstSnapshot = state.snapshots[0]
  const latestSnapshot = state.snapshots[state.snapshots.length - 1]

  // 如果渲染时间还早于第一个快照，停在起点
  if (renderTimeMs <= firstSnapshot.timeMs) {
    return {
      position: { x: firstSnapshot.point.x, y: firstSnapshot.point.y },
      isMoving: false,
      hasPendingMotion: state.snapshots.length > 1
    }
  }

  // 在两个相邻快照之间插值
  for (let index = 1; index < state.snapshots.length; index++) {
    const previousSnapshot = state.snapshots[index - 1]
    const nextSnapshot = state.snapshots[index]

    if (renderTimeMs > nextSnapshot.timeMs) continue

    const position = interpolateSnapshots(previousSnapshot, nextSnapshot, renderTimeMs)
    const isMoving = !isSamePoint(previousSnapshot.point, nextSnapshot.point)
      && renderTimeMs < nextSnapshot.timeMs

    return {
      position,
      isMoving,
      hasPendingMotion: latestSnapshot.timeMs > renderTimeMs
    }
  }

  // 没有足够的快照进行插值，尝试外推
  if (state.snapshots.length < 2) {
    return {
      position: { x: latestSnapshot.point.x, y: latestSnapshot.point.y },
      isMoving: false,
      hasPendingMotion: false
    }
  }

  // 外推
  const previousSnapshot = state.snapshots[state.snapshots.length - 2]
  const segmentDurationMs = latestSnapshot.timeMs - previousSnapshot.timeMs

  if (segmentDurationMs <= 0) {
    return {
      position: { x: latestSnapshot.point.x, y: latestSnapshot.point.y },
      isMoving: false,
      hasPendingMotion: false
    }
  }

  const velocityX = (latestSnapshot.point.x - previousSnapshot.point.x) / segmentDurationMs
  const velocityY = (latestSnapshot.point.y - previousSnapshot.point.y) / segmentDurationMs

  const cappedExtrapolationMs = Math.min(
    Math.max(renderTimeMs - latestSnapshot.timeMs, 0),
    config.maxExtrapolationMs
  )
  const hasVelocity = Math.abs(velocityX) > 0.0001 || Math.abs(velocityY) > 0.0001

  return {
    position: {
      x: latestSnapshot.point.x + velocityX * cappedExtrapolationMs,
      y: latestSnapshot.point.y + velocityY * cappedExtrapolationMs
    },
    isMoving: hasVelocity && cappedExtrapolationMs < config.maxExtrapolationMs,
    hasPendingMotion: hasVelocity && cappedExtrapolationMs < config.maxExtrapolationMs
  }
}
```

### 4.4 快照管理

快照不能无限积累，需要定期清理：

```typescript
function pruneSnapshots(
  state: IOtherPlayerMotionState,
  renderTimeMs: number,
  retentionMs: number
): void {
  if (state.snapshots.length <= 2) return

  const pruneBeforeTimeMs = renderTimeMs - retentionMs

  while (
    state.snapshots.length > 2 &&
    state.snapshots[1].timeMs < pruneBeforeTimeMs
  ) {
    state.snapshots.shift()
  }
}
```

## 五、Hard Snap：漂移过大时的紧急修正

即使有插值和外推，如果客户端状态和服务器权威位置差距过大（比如玩家快速移动、或网络长时间中断），平滑过渡反而会让误差更明显。这时需要"硬切换"。

### 5.1 触发条件

```typescript
interface IOtherPlayerMotionConfig {
  speedPxPerSecond: number
  interpolationDelayMs: number
  hardSnapDistance: number        // 超过此距离触发硬切换
  stalePathThresholdMs: number    // 数据过期阈值
  maxExtrapolationMs: number
  snapshotRetentionMs: number
}

function shouldHardSnap(
  state: IOtherPlayerMotionState,
  latestPoint: { x: number, y: number },
  receivedAtMs: number,
  config: IOtherPlayerMotionConfig
): boolean {
  // 条件1：数据过期（距离上次权威数据超过阈值）
  const latestAuthorityTimeMs = getLatestAuthorityTime(state)
  if (latestAuthorityTimeMs === null) return true

  const hasStaleGap = receivedAtMs - latestAuthorityTimeMs > config.stalePathThresholdMs

  // 条件2：漂移过大（当前渲染位置与目标位置距离超过阈值）
  const driftDistance = getDistance(state.renderPosition, latestPoint)
  const isDrifting = driftDistance > config.hardSnapDistance

  return hasStaleGap && isDrifting
}
```

### 5.2 执行硬切换

```typescript
function performHardSnap(
  state: IOtherPlayerMotionState,
  position: { x: number, y: number },
  receivedAtMs: number
): void {
  state.renderPosition = { x: position.x, y: position.y }
  state.lastSampleTimeMs = receivedAtMs
  state.lastMotionEndTimeMs = null
  state.snapshots = [{ point: { x: position.x, y: position.y }, timeMs: receivedAtMs }]
  state.activeReplayPath = null
  state.bufferedReplayPaths = []
  state.hasPendingMotion = false
}
```

## 六、接收数据后的处理流程

### 6.1 主入口

```typescript
function ingestOtherPlayerMovePath(
  state: IOtherPlayerMotionState,
  points: INormalizedMovePoint[],
  receivedAtMs: number,
  config: IOtherPlayerMotionConfig,
  options: { allowHardSnap?: boolean, durationMs?: number } = {}
): void {
  if (points.length === 0) return

  const latestPoint = points[points.length - 1]
  const allowHardSnap = options.allowHardSnap !== false

  // 检查是否需要 Hard Snap
  const shouldHardSnap = allowHardSnap
    && hasStaleGap(state, receivedAtMs, config.stalePathThresholdMs)
    && getDistance(state.renderPosition, latestPoint) > config.hardSnapDistance

  if (shouldHardSnap) {
    performHardSnap(state, latestPoint, receivedAtMs)
    return
  }

  // 如果不允许 Hard Snap（播放动画时），强制使用 Replay Path
  if (!allowHardSnap) {
    state.snapshots = []
    const anchorPoint = findReplayQueuedEndPoint(state)
    const scheduledStartTimeMs = getReplayQueuedEndTime(state) ?? receivedAtMs

    // 使用速度驱动的路径构建（V1 协议降级方案）
    const replayPath = buildScheduledMotionPath(
      anchorPoint,
      points,
      scheduledStartTimeMs,
      config.speedPxPerSecond
    )

    if (!replayPath) return

    if (!state.activeReplayPath) {
      state.activeReplayPath = replayPath
    } else {
      state.bufferedReplayPaths.push(replayPath)
    }
    state.hasPendingMotion = true
    return
  }

  // 清除旧数据，进入插值模式
  state.activeReplayPath = null
  state.bufferedReplayPaths = []

  // 检查是否有有效的时间戳
  if (hasTimedOffsets(points)) {
    // V2 协议：使用时间驱动的路径
    const anchorPoint = getLatestAuthorityPoint(state)
    const snapshots = buildTimedSnapshots(anchorPoint, points, receivedAtMs)

    if (snapshots.length === 0) return

    appendSnapshots(state, snapshots)
    state.lastMotionEndTimeMs = null
    state.hasPendingMotion = true
  } else {
    // V1 协议：使用速度驱动的路径
    const replayPath = buildScheduledMotionPath(
      getLatestAuthorityPoint(state),
      points,
      receivedAtMs + config.interpolationDelayMs,
      config.speedPxPerSecond
    )

    if (!replayPath) return

    state.activeReplayPath = replayPath
    state.hasPendingMotion = true
  }
}
```

### 6.2 每帧推进

```typescript
interface IOtherPlayerMotionSample {
  position: { x: number, y: number }
  velocity: { x: number, y: number }
  isMoving: boolean
}

function advanceOtherPlayerMotion(
  state: IOtherPlayerMotionState,
  nowMs: number,
  config?: IOtherPlayerMotionConfig
): IOtherPlayerMotionSample {
  const previousPosition = { x: state.renderPosition.x, y: state.renderPosition.y }

  // 优先使用 Replay Path
  const sampledState = (state.activeReplayPath || state.bufferedReplayPaths.length > 0)
    ? sampleReplayPath(state, nowMs)
    : null

  // 降级到 Snapshot 插值
  const nextState = sampledState || (
    config
      ? sampleSnapshotsWithBuffer(state, nowMs, config)
      : {
          position: { x: state.renderPosition.x, y: state.renderPosition.y },
          isMoving: false,
          hasPendingMotion: false
        }
  )

  // 更新渲染位置
  state.renderPosition = { x: nextState.position.x, y: nextState.position.y }
  state.hasPendingMotion = nextState.hasPendingMotion

  // 判断运动是否结束
  if (nextState.isMoving || nextState.hasPendingMotion) {
    state.lastMotionEndTimeMs = null
  } else if ((state.snapshots.length > 0 || state.lastSampleTimeMs > 0) && state.lastMotionEndTimeMs === null) {
    state.lastMotionEndTimeMs = nowMs
  }

  // 计算速度
  const velocity = {
    x: state.renderPosition.x - previousPosition.x,
    y: state.renderPosition.y - previousPosition.y
  }

  state.lastSampleTimeMs = Math.max(state.lastSampleTimeMs, nowMs)

  return {
    position: { x: state.renderPosition.x, y: state.renderPosition.y },
    velocity,
    isMoving: nextState.isMoving
  }
}
```

## 七、完整配置参数

```typescript
const OTHER_PLAYER_MOTION_CONFIG = {
  // 插值延迟：故意延迟渲染时间以积累足够的位置样本
  // 越高越平滑，但响应越慢
  interpolationDelayMs: 150,

  // 硬切换距离：超过此距离触发硬切换
  // 过小会导致频繁跳动，过大会让角色"飘移"过久
  hardSnapDistance: 200,

  // 数据过期阈值：超过此时间未收到新数据，视为过期
  stalePathThresholdMs: 500,

  // 外推上限：预测角色当前位置的最大时间
  // 越大越能填补网络空白，但误差也越大
  maxExtrapolationMs: 150,

  // 快照保留时间：保留最近 N 毫秒的位置快照
  snapshotRetentionMs: 600,

  // 移动速度：用于 V1 协议的速度驱动路径计算
  speedPxPerSecond: 200,

  // 方向偏向：用于平滑方向切换
  directionBias: { x: 0, y: 0 },

  // 方向切换阈值
  turnSwitchThreshold: 0.1,

  // 动画混合时间
  animationMixDuration: 0.1,

  // 停止动画宽限期
  stopAnimationGraceMs: 100,
}
```

## 八、整体流程图

```
服务器广播玩家移动数据 (USER_MOVE_DOWN)
           │
           ▼
┌─────────────────────────────────────────────────┐
│  normalizeUserMoveDownMessage                    │
│  - 解析 V1/V2 协议                               │
│  - 统一为 INormalizedMovePoint[]                │
│  - 检测 seq 去重                                 │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│  ingestOtherPlayerMovePath                       │
│  ├─ shouldHardSnap？ → performHardSnap          │
│  ├─ !allowHardSnap？ → buildScheduledMotionPath │
│  ├─ hasTimedOffsets？ → buildTimedSnapshots     │
│  └─ 否则 → buildScheduledMotionPath            │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│  advanceOtherPlayerMotion (每帧调用)             │
│  ├─ sampleReplayPath (Replay Path 优先)         │
│  ├─ sampleSnapshotsWithBuffer (插值降级)        │
│  └─ extrapolateFromVelocity (外推超界)          │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
              渲染角色于 renderPosition
```

## 九、实际使用示例

在游戏场景中调用运动同步：

```typescript
// OtherPlayersManager.ts
public addMovePoints(
  momoId: string,
  moveList: Array<{ x: number, y: number, offsetMs?: number }>,
  durationMs?: number,
): void {
  const poolIndex = this.activePlayers.get(momoId)
  if (poolIndex === undefined) return

  const playerInfo = this.objectPool[poolIndex]

  // 应用移动数据到运动状态机
  ingestOtherPlayerMovePath(
    playerInfo.motionState,
    moveList,
    Date.now(),
    OTHER_PLAYER_MOTION_CONFIG,
    { allowHardSnap: true, durationMs }
  )
}

// 每帧更新
public update(): void {
  const currentTime = Date.now()

  this.activePlayers.forEach((poolIndex, momoId) => {
    const pooledObj = this.objectPool[poolIndex]

    // 获取运动采样
    const motionSample = advanceOtherPlayerMotion(
      pooledObj.motionState,
      currentTime,
      OTHER_PLAYER_MOTION_CONFIG
    )

    // 应用位置
    pooledObj.spine.setPosition(motionSample.position.x, motionSample.position.y)

    // 根据速度更新朝向
    const velocityX = motionSample.position.x - pooledObj.lastPosition.x
    const velocityY = motionSample.position.y - pooledObj.lastPosition.y

    if (Math.abs(velocityX) > 0.1 || Math.abs(velocityY) > 0.1) {
      const nextDirection = resolveDirectionFromVelocity(velocityX, velocityY)
      // 更新动画...
    }

    pooledObj.lastPosition = { x: motionSample.position.x, y: motionSample.position.y }
  })
}
```

## 十、总结

多人游戏的位置同步，本质上是在 **"及时性"** 和 **"平滑性"** 之间做权衡：

| 策略 | 适用场景 | 优点 | 缺点 |
|------|----------|------|------|
| **Hard Snap** | 网络中断、距离过远 | 快速修正误差 | 突兀跳动 |
| **Replay Path** | V2 协议带时间戳 | 精确可控 | 需要服务器支持 |
| **Snapshot 插值** | V1 协议 | 平滑流畅 | 有滞后感 |
| **外推** | 网络波动时填补空白 | 连续性 | 可能预测错误 |

好的同步系统会**分层组合这些策略**：优先使用 V2 协议的精确时间戳；当 V1 时降级到速度驱动路径；当差距过大时触发 Hard Snap。最终让玩家感受到的是"流畅"和"跟手"，而底层是一套精心设计的降级与恢复机制。