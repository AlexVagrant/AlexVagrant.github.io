---
layout: post
title: "WebSocket 多人移动同步：Protobuf 差分上传、双缓冲插值与状态复现"
date: 2026-06-17
category: gameDevelopment
tags: [WebSocket, Protobuf, Multiplayer, Three.js, Network Sync]
---

最近读了一份用 Three.js 做的画风多人游戏源码，它的 WebSocket 移动同步方案设计得很干净，从连接管理到数据编码再到客户端插值复现，各层拆得很清楚。这篇文章把核心链路梳理出来。

<!-- more -->

## 整体数据流

```
本地玩家物理引擎
    ↓ 每帧计算 position / rotation
characters._update()
    ↓ 写入 _connection._data 对象
setInterval(updateRate)
    ↓ _retrieveChangedData() 差分检测
    ↓ protobuf 编码
WebSocket.send() ────────→ 服务器中继 ────────→ 远程客户端
                                                      ↓ WebSocket.onmessage
                                                      ↓ 前 N 字节 = 客户端 ID
                                                      ↓ 剩余 = protobuf 解码
                                                      ↓ _addClient / 更新 _clients Map
                                                      ↓ 每帧 lerp/slerp 平滑插值
                                                      ↓ BatchedMesh 渲染
```

## 一、连接管理：MicroRealmConnection

整个多人系统围绕 `MicroRealmConnection` 类构建，它封装了 WebSocket 的生命周期。

**连接建立**：使用 `permessage-deflate` 压缩，binaryType 设为 `arraybuffer`：

```js
this._socket = new WebSocket(
  this._servers[this._serverIndex],
  "permessage-deflate"
);
this._socket.binaryType = "arraybuffer";
```

**混合协议**：同一连接上走两种数据格式：

| 用途 | 格式 | 说明 |
|------|------|------|
| 握手、房间加入、ping/pong | **JSON** | `{"r": ["prefix", "roomName"]}` |
| 高频位置/状态同步 | **Protobuf 二进制** | 前 N 字节是客户端 ID 字符串，剩余是编码后的状态数据 |

**自动重连**：断开后根据场景选择重试策略——如果从未连上过（`_serverFirstConnection === true`），切换下一个服务器地址重试；如果曾经连上过但本地数据有变化，也会重试。

## 二、Protobuf 动态 Schema

没有手写 `.proto` 文件，而是用 `protobufjs` 在运行时根据初始化数据**动态生成**消息结构：

```js
// 根据 data 对象的字段类型推断 proto schema
const TYPEMAP = { number: "double", string: "string", boolean: "bool" };

function inferJSON(name, data, types) {
  // 遍历 data 的 key/value，生成 proto3 message 定义
  // 支持 repeated 数组字段
}

const schema = inferJSON("RealmData", this._data, this._dataTypes);
const root = new protobuf.Root();
protobuf.parse(schema, root);
this._protoMsg = root.lookupType("RealmData");
```

实际同步的关键字段：

```
p: float[]    // 位置 [x, y, z]
r: float[]    // 欧拉角 [x, y, z]
medium: uint  // 地面 / 空中 / 水中
animation: uint  // 当前动画 ID
bonesFile / modelFiles / animationFiles: string  // 角色外观
tag: string    // 玩家名称标签
networkEvent: string  // 自定义事件(如 emoji 表情)
```

## 三、移动上传：差分 + 定时发送

### 3.1 每帧写入数据对象

物理引擎每帧计算出的位置和旋转，直接写入连接持有的数据对象：

```js
// 位置：保留 2 位小数，减少传输体积
this._connection._data.p = this._localObject.position.toArray()
  .map(v => +Number(v).toFixed(2));

// 旋转
this._connection._data.r = this._localObject.rotation.toArray()
  .slice(0, 3).map(v => +Number(v).toFixed(2));

// 其他状态字段
Object.keys(this._localObject.userData).forEach(key => {
  this._connection._data[key] = this._localObject.userData[key];
});
```

### 3.2 差分检测

不是每帧都发送全部数据。用一个定时器以固定频率（`updateRate`，默认 35ms，约 28fps）触发 `_relay()`，它会比较当前数据与上次发送时的快照，**只发送变化的字段**：

```js
_retrieveChangedData() {
  const prev = JSON.parse(this._prevData);
  const changes = {};
  Object.keys(this._data).forEach(key => {
    if (JSON.stringify(prev[key]) !== JSON.stringify(this._data[key])) {
      changes[key] = this._data[key];
    }
  });
  return changes;
}
```

如果没有任何字段变化，这一帧就跳过发送。

### 3.3 Protobuf 编码发送

变化的字段通过 Protobuf 编码为二进制 ArrayBuffer 发送：

```js
_sendRelayedData(data) {
  const msg = this._protoMsg.create(data);
  const buf = this._protoMsg.encode(msg).finish();
  this._socket.send(buf);  // 二进制发送，比 JSON 省带宽
}
```

## 四、移动复现：双缓冲插值 + 分级更新

### 4.1 消息接收

收到二进制消息时，前 `_localIDLength` 字节是**客户端 ID 字符串**，剩余部分用 Protobuf 解码为状态对象：

```js
_message(event) {
  if (typeof event.data !== "string") {
    // 二进制 Protobuf 消息
    const clientId = decoder.decode(
      event.data.slice(0, this._localIDLength)
    );
    const state = this._protoMsg.decode(
      new Uint8Array(event.data.slice(this._localIDLength))
    );

    const existing = this._clients.get(clientId);
    if (existing) {
      // 已存在：更新状态
      Object.keys(state).forEach(key => {
        existing[key] = state[key];
      });
    } else {
      // 新客户端：创建远程对象
      this._clients.set(clientId, state);
      this._addClient(clientId, state);
    }
  }
}
```

### 4.2 双缓冲平滑插值

每个远程角色维护 **prev / next 双缓冲**，结合物理子步（substep）的累积器做线性插值：

```js
// 在物理子步循环中更新
remote.nextPosition.fromArray(data.p);
remote.prevPosition.copy(remote.nextPosition);

// 渲染时用子步累积器做插值 (0~1)
const t = this._collisionPhysics._deltaRatioAccumulator;
remote.position.lerpVectors(
  remote.prevPosition,   // 上一物理帧位置
  remote.nextPosition,   // 当前目标位置
  t
);

// 旋转用 SLERP
remote.quaternion.slerpQuaternions(
  remote.prevRotation,
  remote.nextRotation,
  t
);
```

这种方法的好处是：
- 位置和旋转的过渡与本地物理帧率解耦
- 即使网络包到达间隔不均匀，渲染依然平滑
- 不需要维护复杂的快照缓冲区

### 4.3 位置快照（瞬移保护）

如果远程位置跳变过大（超过 `_positionDeltaLimitSnap`），说明网络出现了严重断档，此时跳过平滑插值，直接瞬移到目标位置：

```js
if (nextPosition.distanceTo(prevPosition) > this._positionDeltaLimitSnap) {
  // 跳过平滑，直接设置
  remote.position.copy(nextPosition);
}
```

### 4.4 分级更新频率

动画更新不是所有角色一视同仁。根据与本地玩家的距离做分级：

```js
// 距离越远，更新间隔越长
const mult = math.fit(
  distance,
  UPDATE_DISTANCE * 0.1,  // 近处阈值
  UPDATE_DISTANCE,         // 最大距离
  0,                       // 近处不跳帧
  UPDATE_DISTANCE_MULT     // 远处最大跳帧倍数
);

if (renderInfo.time - lastUpdate < mult) {
  return;  // 跳过本帧更新
}
```

这样远处 NPC 不会浪费 CPU 做高频动画混合。

## 五、连接断开处理

### 5.1 角色移除动画

当服务器通知某个客户端离开（`leave` 字段），不是直接删除对象，而是播放一个缩小消失动画：

```js
remote.isBeingRemoved = true;
createTween(remote.scale, {
  to: { x: 0, y: 0, z: 0 },
  ease: "power2.out",
  duration: 0.15,
  onComplete: () => {
    this._charactersObjects.delete(id);
  }
});
```

### 5.2 网络事件传递

自定义事件（如 emoji 表情）通过 `networkEvent` 字段传递。为了避免状态污染，这个字段用 `Object.defineProperty` 做成了"即用即焚"：

```js
Object.defineProperty(data, "networkEvent", {
  enumerable: true,
  get: () => "",
  set: (value) => {
    if (value && typeof value === "string") {
      remote.networkEvents.push(value);  // 推入事件队列
    }
  }
});
```

每帧处理事件队列，清空后触发游戏逻辑，这样就避免了"同一事件被重复消费"的问题。

## 六、性能优化细节

| 优化点 | 实现 |
|--------|------|
| 位置精度 | `toFixed(2)` 保留两位小数 |
| 数据压缩 | WebSocket `permessage-deflate` |
| 传输格式 | Protobuf 二进制，比 JSON 小约 60-70% |
| 发送频率 | 差分检测 + 定时器控制，无变化不发送 |
| 渲染频率 | 根据距离分级跳帧 |
| 对象池 | `BatchedMesh` 合并所有角色到一个 draw call |

## 总结

这套方案用几个非常务实的策略实现了流畅的多人移动同步：

- **混合协议**：JSON 管握手，Protobuf 管高频数据
- **差分上传**：只发送变化的字段，配合定时器控制频率
- **双缓冲插值**：prev/next + 子步累积器，与物理帧率解耦
- **位置快照**：跳变过大时直接瞬移，防止"飘移"
- **分级更新**：远处角色降低动画更新频率
- **优雅断连**：角色离开播放缩小消失动画

和 Phaser 那篇的 "Replay Path + Snapshot 插值" 方案相比，这套方案更轻量——它不需要服务器下发精确的时间戳路径，而是依赖客户端的双缓冲平滑。两种方案各有适用场景：Phaser 方案更适合**路径明确的网格移动**（格子游戏），这套方案更适合**物理驱动的自由移动**（3D 开放世界）。

> 本文基于对画风游戏 `messenger.abeto.co` 客户端代码的分析。源码注释头 `/* by abeto - https://abeto.co */`。
