---
layout: post
title: "ViewModel 模式中的命名规范：resolve、schedule、get 与 pick"
date: 2026-05-12
category:
tags: [Architecture, TypeScript, Vue, Naming Conventions]
---

在复杂 UI 组件中，ViewModel 模式可以将业务数据与渲染逻辑解耦。但当功能模块逐渐膨胀，如果函数命名没有统一规范，阅读和维护成本会快速增长。本文从实际项目中提炼出一套可复用的命名约定，覆盖纯转换、副作用调度、值提取等常见场景。

<!-- more -->

## 一、ViewModel 模式概览

核心思路分三层：

1. **定义 View 接口** — 只包含组件渲染需要的数据，不泄漏业务模型细节
2. **编写 `resolve*View` 函数** — 纯函数，从 domain/store 模型转换到 View 接口
3. **组件只消费 View** — props 类型依赖 View 接口，不直接依赖原始业务数据

```
Store / Domain Model
        │
        ▼
  resolveFeatureView()      ← ViewModel（纯函数）
        │
        ▼
  IFeatureView              ← View 接口
        │
        ▼
  Component.vue             ← 只消费 View
```

好处：转换逻辑可单测、组件职责清晰、同一份 domain 数据可以产出多种 View 变体。

## 二、函数动词前缀：五类标准语义

当一个功能模块包含多个文件时，用一致的动词前缀区分函数职责，让调用方无需阅读实现即可理解行为。

### `resolve*` — 纯转换

纯函数，无副作用，相同输入总是产生相同输出。用于将一种数据形状转换为另一种。

```typescript
// domain → View
export function resolveFeatureView(
  config: Config,
  data: DomainData | null,
): IFeatureView | null { ... }

// View → 子视图（二次 resolve）
export function resolveFeatureStatusState(
  view: IFeatureView,
): IFeatureStatusState { ... }

// 入口：组装顶层列表
export function resolveFeatureEntries(
  params: { level: number, data: DomainData | null },
): IFeatureEntry[] { ... }
```

特征：
- 接收数据，返回转换后的结果
- 不修改参数
- 不发请求、不启动定时器
- 可以链式调用（一个 resolve 的输出作为下一个 resolve 的输入）

### `schedule*` — 启动副作用并返回清理函数

启动定时器、订阅、轮询等副作用，始终返回一个 `() => void` 清理函数。

```typescript
// scheduleFeatureRefresh.ts
export function scheduleFeatureRefresh({
  deadline,
  refresh,
}: {
  deadline: { remainingSeconds: number | null, autoRefresh: boolean }
  refresh: () => void | Promise<void>
}): () => void {
  if (!deadline.autoRefresh || deadline.remainingSeconds == null || deadline.remainingSeconds <= 0) {
    return () => {}  // guard：不需要调度时返回 no-op
  }

  const timer = globalThis.setTimeout(() => {
    void refresh()
  }, deadline.remainingSeconds * 1000)

  return () => {
    globalThis.clearTimeout(timer)
  }
}
```

```typescript
// scheduleFeatureCarousel.ts
export function scheduleFeatureCarousel({
  itemCount,
  onTick,
}: {
  itemCount: number
  onTick: () => void
}): () => void {
  if (itemCount <= 1) return () => {}

  const timer = globalThis.setInterval(() => {
    onTick()
  }, CAROUSEL_INTERVAL)

  return () => {
    globalThis.clearInterval(timer)
  }
}
```

这个模式的模板非常固定：

```typescript
function scheduleX(config: {...}): () => void {
  if (shouldNotSchedule) return () => {}   // guard
  const timer = globalThis.setXxx(...)     // start
  return () => { globalThis.clearXxx(timer) }  // cleanup
}
```

组件侧消费方式也很统一：

```typescript
let stop = () => {}

watch(() => props.someDep, (dep) => {
  stop()
  stop = scheduleFeatureX({ dep, onTick: handleTick })
}, { immediate: true })

onBeforeUnmount(() => stop())
```

### `get*` — 简单取值或计算

用于提取、计算、格式化单个值。通常是无副作用、逻辑较轻的纯函数。

```typescript
// 从原始数据中提取并规范化
function getCollectedCount(progress: Progress | null, key: string): number {
  return normalizeCount(progress?.collected[key])
}

// 计算派生值
export function getProgressFillWidth(ratio: number): number {
  const safe = Math.max(0, Math.min(1, ratio))
  return Math.round(MAX_WIDTH * safe)
}

// 过滤 + 排序的查询
function getMeaningfulColors(
  data: DomainData,
  progress: Progress | null,
): string[] { ... }
```

与 `resolve*` 的区别：`get*` 通常返回标量或简单数组，不返回复杂的 View 对象。`resolve*` 做结构性转换，`get*` 做值级提取。

### `pick*` — 择优选择，带 fallback 链

当需要从多个候选来源中选择数据，且有明确的优先级和兜底逻辑时使用。

```typescript
function pickRewards(
  data: DomainData,
  progress: Progress | null,
): RewardItem[] {
  // 优先级 1：进度中携带的奖励
  const progressRewards = progress?.rewardList ?? []
  if (progressRewards.length > 0) return progressRewards

  // 优先级 2：匹配当前层级的奖励
  const currentLevel = progress?.currentLevel
  if (currentLevel != null) {
    const matched = data.rewardList.find(r => r.level === currentLevel)
    if (matched?.items.length) return matched.items
  }

  // 兜底：第一层的奖励
  return data.rewardList[0]?.items ?? []
}
```

`pick*` 与 `get*` 的区别：`pick*` 强调"有优先级的择优过程"，带有明确的 fallback 链。

### `stop*` — 阻止事件行为

用于事件处理器中阻止默认行为或冒泡。

```typescript
export function stopFeatureUserClick(event: { stopPropagation: () => void }) {
  event.stopPropagation()
}
```

这类函数通常很短，但单独抽取的好处是：
- 给阻止行为一个语义化的名字
- 可以在测试中验证调用
- 让组件模板中 `@click="stopFeatureUserClick"` 比内联箭头函数更清晰

## 三、函数命名全称结构

公开函数遵循三段式命名：

```
<动词><模块名><名词>
```

例如：
- `resolveCheckInBannerView` — resolve + 模块名 + View
- `scheduleCheckInBannerRefresh` — schedule + 模块名 + Refresh
- `getCheckInBannerProgressWidth` — get + 模块名 + ProgressWidth

模块名中缀让全局搜索（`grep "CheckInBanner"`）可以一次性命中该模块所有公开 API，对于大型项目定位代码非常高效。

内部辅助函数可以不包含模块名中缀（如 `normalizeCount`、`parseLabel`），只在与公开函数同一文件内使用。

## 四、接口命名

| 元素 | 约定 | 示例 |
|------|------|------|
| 接口前缀 | `I` | `IFeatureView` |
| View 接口后缀 | `View` | `IFeatureView`、`IFeatureItemView` |
| 状态接口后缀 | `State` | `IFeatureStatusState` |
| 入口类型 | `Entry` | `IFeatureEntry` |
| 常量 | `UPPER_SNAKE_CASE` | `FEATURE_PROGRESS_MAX_WIDTH` |

View 类型的子结构用 `*View` 后缀，表明它也是渲染用途的数据：

```typescript
interface IFeatureView {
  items: IFeatureItemView[]
  badge: IFeatureBadgeView | null
}
```

## 五、文件命名

```
featureView.ts              # View 接口定义 + 主 resolver
featureStatus.ts            # 状态子视图 resolver
featureProgress.ts          # 进度计算工具
featureClick.ts             # 事件处理
featureTitleRefresh.ts      # 定时刷新调度
featureCarousel.ts          # 轮播调度
featureState.ts             # 入口 resolver + 类型汇总
```

每个文件单一职责，文件名直接对应导出函数的核心名词部分。`*State.ts` 通常作为模块入口，负责聚合子模块并对外暴露统一的入口函数。

## 六、函数分层调用图

```
featureState.ts           resolveFeatureEntries()       ← 入口
    │ 调用
    ▼
featureView.ts            resolveFeatureView()          ← 核心 ViewModel
    │ 被消费
    ├── featureStatus.ts      resolveFeatureStatusState() ← View → 状态 UI 模型
    ├── featureProgress.ts    getFeatureProgressFillWidth()
    ├── featureRefresh.ts     scheduleFeatureRefresh()
    └── featureCarousel.ts    scheduleFeatureCarousel()
```

组件层只与 `featureState.ts`（入口）交互获取 View，再将 View 分别传给各个 `resolve*` / `schedule*` / `get*` 工具函数驱动渲染和副作用。

## 七、完整使用示例

下面通过一个"每日签到横幅"（Daily Check-in Banner）功能，从头演示如何应用这套规范。需求：在页面顶部展示签到进度条、奖励轮播、倒计时刷新，点击弹出签到弹窗。

### 7.1 第一步：定义 View 接口和主 resolver

`checkInBannerView.ts` — 这是模块的核心文件：

```typescript
import type { ICheckInProgress, IRewardItem } from '@/interfaces/common'

// View 子结构：签到进度中的每个指标
export interface ICheckInBannerMetricView {
  label: string
  current: number
  target: number
}

// View 子结构：标题徽章
export interface ICheckInBannerBadgeView {
  iconUrl: string
  remainingSeconds: number | null
  autoRefresh: boolean
}

// 核心 View 接口：组件渲染所需的全部数据
export interface ICheckInBannerView {
  userName: string
  metrics: ICheckInBannerMetricView[]
  progressRatio: number       // 0~1
  statusText: string
  rewards: IRewardItem[]
  badge: ICheckInBannerBadgeView | null
  isCompleted: boolean
}

// --- 内部辅助函数 ---

function normalizeCount(value: number | string | null | undefined): number {
  const n = Number(value)
  return Number.isFinite(n) ? n : 0
}

function getCurrent(progress: ICheckInProgress | null, key: string): number {
  return normalizeCount(progress?.current[key])
}

function getTarget(progress: ICheckInProgress | null, key: string): number {
  return normalizeCount(progress?.target[key])
}

function pickRewards(
  progress: ICheckInProgress | null,
  fallbackRewards: IRewardItem[],
): IRewardItem[] {
  const fromProgress = progress?.rewards ?? []
  if (fromProgress.length > 0) return fromProgress

  const currentLevel = progress?.currentLevel
  if (currentLevel != null) {
    const matched = fallbackRewards.find(r => r.level === currentLevel)
    if (matched?.items.length) return matched.items
  }

  return fallbackRewards[0]?.items ?? []
}

// --- 公开 API ---

export function resolveCheckInBannerView(
  activity: ICheckInActivity | null,
  progress?: ICheckInProgress | null,
): ICheckInBannerView | null {
  if (!activity) return null

  const resolved = progress ?? activity.progress ?? null
  const metricKeys = Object.keys(resolved?.target ?? {})
    .filter(key => getTarget(resolved, key) > 0)

  // 构建指标列表
  const metrics: ICheckInBannerMetricView[] = metricKeys.map(key => ({
    label: key,
    current: getCurrent(resolved, key),
    target: getTarget(resolved, key),
  }))

  // 计算进度
  const total = metricKeys.reduce((sum, k) => sum + getTarget(resolved, k), 0)
  const done = metricKeys.reduce((sum, k) => sum + getCurrent(resolved, k), 0)

  // 判断状态文案
  const allDone = metricKeys.length > 0 && done >= total
  const hasProgress = done > 0
  const statusText = allDone ? '签到完成' : hasProgress ? '继续加油' : '每日签到领奖励'

  return {
    userName: activity.userName ?? '',
    metrics,
    progressRatio: total > 0 ? Math.min(1, done / total) : 0,
    statusText,
    rewards: pickRewards(resolved, activity.rewards),
    badge: activity.badge?.iconUrl ? {
      iconUrl: activity.badge.iconUrl,
      remainingSeconds: activity.badge.remainingSeconds,
      autoRefresh: true,
    } : null,
    isCompleted: allDone,
  }
}
```

关键点：
- `ICheckInBannerView` 只包含渲染所需的数据，不暴露 `ICheckInActivity` 的原始结构
- 内部辅助函数（`normalizeCount`、`getCurrent`、`pickRewards`）不加模块中缀，因为只在文件内使用
- `resolveCheckInBannerView` 是唯一的公开导出，组件只需要关心这一个入口

### 7.2 第二步：添加状态子视图

`checkInBannerStatus.ts` — 对 View 做二次 resolve，产出状态栏渲染模型：

```typescript
import type { ICheckInBannerView } from './checkInBannerView'

export interface ICheckInBannerStatusState {
  mode: 'pending' | 'progress' | 'completed'
  text: string
  missingLabels: string[]
}

export function resolveCheckInBannerStatusState(
  view: ICheckInBannerView,
): ICheckInBannerStatusState {
  if (view.isCompleted) {
    return { mode: 'completed', text: '已全部完成', missingLabels: [] }
  }

  const missing = view.metrics
    .filter(m => m.current < m.target)
    .map(m => `${m.label} x${m.target - m.current}`)

  if (missing.length === view.metrics.length) {
    return { mode: 'pending', text: '每日签到领奖励', missingLabels: [] }
  }

  return { mode: 'progress', text: '还差', missingLabels: missing }
}
```

### 7.3 第三步：添加辅助工具文件

`checkInBannerProgress.ts` — 进度条宽度计算：

```typescript
export const CHECK_IN_BANNER_MAX_FILL_WIDTH = 280

export function getCheckInBannerProgressWidth(ratio: number): number {
  const safe = Math.max(0, Math.min(1, ratio))
  return Math.round(CHECK_IN_BANNER_MAX_FILL_WIDTH * safe)
}
```

`checkInBannerClick.ts` — 事件处理：

```typescript
export function stopCheckInBannerClick(event: { stopPropagation: () => void }) {
  event.stopPropagation()
}
```

`checkInBannerRefresh.ts` — 倒计时刷新调度：

```typescript
import type { ICheckInBannerBadgeView } from './checkInBannerView'

export function scheduleCheckInBannerRefresh({
  badge,
  refresh,
}: {
  badge: ICheckInBannerBadgeView | null
  refresh: () => void | Promise<void>
}): () => void {
  if (!badge?.autoRefresh || badge.remainingSeconds == null || badge.remainingSeconds <= 0) {
    return () => {}
  }

  const timer = globalThis.setTimeout(() => {
    void refresh()
  }, badge.remainingSeconds * 1000)

  return () => { globalThis.clearTimeout(timer) }
}
```

`checkInBannerCarousel.ts` — 奖励轮播调度：

```typescript
export const CHECK_IN_CAROUSEL_INTERVAL = 1500

export function scheduleCheckInBannerCarousel({
  rewardCount,
  onTick,
}: {
  rewardCount: number
  onTick: () => void
}): () => void {
  if (rewardCount <= 1) return () => {}

  const timer = globalThis.setInterval(onTick, CHECK_IN_CAROUSEL_INTERVAL)

  return () => { globalThis.clearInterval(timer) }
}
```

### 7.4 第四步：聚合入口

`checkInBannerState.ts` — 对外暴露统一的入口函数，组装所有模块：

```typescript
import type { ICheckInBannerView } from './checkInBannerView'
import { resolveCheckInBannerView } from './checkInBannerView'

export interface ICheckInBannerEntry {
  type: 'check-in'
  view: ICheckInBannerView
}

export function resolveCheckInBannerEntries({
  activity,
  displayProgress,
}: {
  activity: ICheckInActivity | null
  displayProgress?: ICheckInProgress | null
}): ICheckInBannerEntry[] {
  if (!activity) return []

  const view = resolveCheckInBannerView(activity, displayProgress)
  if (!view) return []

  return [{ type: 'check-in', view }]
}
```

### 7.5 第五步：组件消费

`CheckInBanner.vue` — 组件只依赖 View 和工具函数：

```vue
<script setup lang="ts">
import type { ICheckInBannerView } from './checkInBannerView'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { stopCheckInBannerClick } from './checkInBannerClick'
import { getCheckInBannerProgressWidth } from './checkInBannerProgress'
import { scheduleCheckInBannerCarousel } from './checkInBannerCarousel'
import { scheduleCheckInBannerRefresh } from './checkInBannerRefresh'
import { resolveCheckInBannerStatusState } from './checkInBannerStatus'

const props = defineProps<{
  view: ICheckInBannerView
  onRefresh?: () => void | Promise<void>
}>()

const emit = defineEmits<{ openDialog: [] }>()

// 状态子视图
const status = computed(() => resolveCheckInBannerStatusState(props.view))

// 进度条宽度
const fillWidth = computed(() => px2vw(getCheckInBannerProgressWidth(props.view.progressRatio)))

// 奖励轮播
const activeRewardIndex = ref(0)
const activeReward = computed(() => props.view.rewards[activeRewardIndex.value] ?? null)

let stopCarousel = () => {}
watch(
  () => props.view.rewards,
  (rewards) => {
    stopCarousel()
    stopCarousel = scheduleCheckInBannerCarousel({
      rewardCount: rewards.length,
      onTick: () => {
        activeRewardIndex.value = (activeRewardIndex.value + 1) % rewards.length
      },
    })
  },
  { immediate: true },
)

// 等级变更时重置轮播
watch(() => props.view.currentLevel, () => {
  activeRewardIndex.value = 0
})

// 倒计时刷新
let stopRefresh = () => {}
watch(
  () => props.view.badge,
  (badge) => {
    stopRefresh()
    stopRefresh = scheduleCheckInBannerRefresh({
      badge,
      refresh: props.onRefresh ?? (() => {}),
    })
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  stopCarousel()
  stopRefresh()
})
</script>

<template>
  <div class="check_in_banner" @click="emit('openDialog')">
    <div class="banner_body">
      <!-- 进度条 -->
      <div class="progress_track">
        <div class="progress_fill" :style="{ width: fillWidth }" />
      </div>
      <!-- 状态文字 -->
      <span :class="`status_text is-${status.mode}`">{{ status.text }}</span>
      <!-- 缺失项列表 -->
      <span v-for="item in status.missingLabels" :key="item" class="missing_tag">
        {{ item }}
      </span>
      <!-- 奖励轮播 -->
      <img
        v-if="activeReward"
        :src="activeReward.icon"
        :alt="activeReward.name"
        class="reward_icon"
      />
      <!-- 徽章 -->
      <img
        v-if="view.badge"
        :src="view.badge.iconUrl"
        class="badge_icon"
        @click="stopCheckInBannerClick"
      />
    </div>
  </div>
</template>
```

### 7.6 第六步：页面中组装

`CheckInRail.vue` — 页面级组件，连接 Store 与 Banner：

```vue
<script setup lang="ts">
import { computed } from 'vue'
import useStore from '../../store'
import { resolveCheckInBannerEntries } from './checkInBannerState'
import CheckInBanner from './CheckInBanner.vue'

const store = useStore()

const entries = computed(() => resolveCheckInBannerEntries({
  activity: store.checkInActivity,
  displayProgress: store.displayCheckInProgress,
}))

async function handleRefresh() {
  await store.fetchLatestActivity()
}
</script>

<template>
  <div v-if="entries.length > 0" class="check_in_rail">
    <CheckInBanner
      v-for="entry in entries"
      :key="entry.type"
      :view="entry.view"
      :on-refresh="handleRefresh"
      @open-dialog="store.openCheckInDialog()"
    />
  </div>
</template>
```

### 7.7 最终文件结构

```
CheckInBannerRail/
├── checkInBannerView.ts             # View 接口 + resolveCheckInBannerView
├── checkInBannerStatus.ts           # resolveCheckInBannerStatusState
├── checkInBannerProgress.ts         # getCheckInBannerProgressWidth
├── checkInBannerClick.ts            # stopCheckInBannerClick
├── checkInBannerRefresh.ts          # scheduleCheckInBannerRefresh
├── checkInBannerCarousel.ts         # scheduleCheckInBannerCarousel
├── checkInBannerState.ts            # resolveCheckInBannerEntries（入口）
├── CheckInBanner.vue                # 组件
├── CheckInRail.vue                  # 页面级组装
├── checkInBannerView.test.ts        # 核心 ViewModel 单测
├── checkInBannerStatus.test.ts      # 状态子视图单测
├── checkInBannerProgress.test.ts
├── checkInBannerClick.test.ts
├── checkInBannerRefresh.test.ts
└── checkInBannerCarousel.test.ts
```

核心 ViewModel 的单元测试示例（`checkInBannerView.test.ts`）：

```typescript
import { describe, expect, it } from 'vitest'
import { resolveCheckInBannerView } from './checkInBannerView'

describe('resolveCheckInBannerView', () => {
  it('returns null when activity is null', () => {
    expect(resolveCheckInBannerView(null)).toBeNull()
  })

  it('returns pending status when no progress made', () => {
    const activity = { userName: 'Alice', target: { coin: 10 }, current: { coin: 0 } }
    const view = resolveCheckInBannerView(activity)
    expect(view).not.toBeNull()
    expect(view!.statusText).toBe('每日签到领奖励')
    expect(view!.progressRatio).toBe(0)
  })

  it('returns completed status when all targets met', () => {
    const activity = { userName: 'Bob', target: { coin: 5 }, current: { coin: 5 } }
    const view = resolveCheckInBannerView(activity)
    expect(view!.isCompleted).toBe(true)
    expect(view!.statusText).toBe('签到完成')
  })

  it('returns partial progress with correct ratio', () => {
    const activity = {
      userName: 'Carol',
      target: { coin: 10, gem: 5 },
      current: { coin: 5, gem: 0 },
    }
    const view = resolveCheckInBannerView(activity)
    expect(view!.progressRatio).toBe(5 / 15)
    expect(view!.isCompleted).toBe(false)
  })
})
```

### 7.8 模板：新建功能模块的 Checklist

当需要新增一个功能模块时，按以下顺序创建文件：

1. **View 接口 + 主 resolver**（`featureView.ts`）
   - 定义 `IFeatureView` 及相关子 View 接口
   - 实现 `resolveFeatureView(domain, progress?) → IFeatureView | null`
   - 内部辅助函数用 `get*`、`pick*`、`normalize*` 命名
   - 先写单测
2. **子视图 resolver**（`featureStatus.ts`、`featureMetrics.ts` 等）
   - 实现 `resolveFeature<子视图>State(view: IFeatureView) → IFeatureXxxState`
3. **数值工具**（`featureProgress.ts` 等）
   - 导出 `getFeature<值名>(...) → number | string` 形式的纯函数 + 常量
4. **事件处理**（`featureClick.ts`）
   - 导出 `stopFeature<行为>(event) → void`
5. **副作用调度**（`featureRefresh.ts`、`featureCarousel.ts` 等）
   - 导出 `scheduleFeature<行为>(config) → () => void`
6. **模块入口**（`featureState.ts`）
   - 导出 `resolveFeatureEntries(params) → IFeatureEntry[]`
7. **组件**（`FeatureBanner.vue`、`FeatureRail.vue`）
   - 只 import View 类型和工具函数，不 import domain 类型

---

## 八、总结

| 前缀 | 语义 | 返回值 | 副作用 |
|------|------|--------|--------|
| `resolve*` | 纯数据转换 | 新数据对象 | 无 |
| `schedule*` | 启动定时/订阅 | `() => void` 清理函数 | 有 |
| `get*` | 取值/简单计算 | 标量或数组 | 无 |
| `pick*` | 择优选择 + fallback | 列表或对象 | 无 |
| `stop*` | 阻止事件 | `void` | 有 |

**一个核心规则**：如果你预期的函数调用方需要在 `watch` 中先调用上一次的 cleanup，那么它应该是 `schedule*`；如果调用方只需要拿返回值直接渲染，那么它应该是 `resolve*` 或 `get*`。

这套规范的核心价值不在于命名本身，而在于**让每个函数的职责在名字上自解释**。新人接手模块时，扫一眼 import 列表就能判断哪些函数有副作用需要管理生命周期，哪些函数是纯数据转换可以直接使用。
