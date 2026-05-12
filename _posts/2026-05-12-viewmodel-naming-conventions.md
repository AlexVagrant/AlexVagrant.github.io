---
layout: post
title: "ViewModel 模块中的命名规范：resolve、schedule、get 与 pick"
date: 2026-05-12
category:
tags: [Architecture, TypeScript, Vue, Naming Conventions]
---

在复杂 UI 模块里，真正让人头疼的，往往不是功能本身，而是“看了函数名还是不知道它会做什么”。有的函数只是组装 View，有的函数会启动定时器，有的函数只是取一个值，但名字却都长得差不多。时间一久，阅读成本和维护成本就会一起上升。

这篇文章想解决的不是“怎么起一个好听的名字”，而是建立一套**能从函数名直接判断职责**的约定。重点只有四类前缀：

- `resolve*`：把输入组织成 View 或其他渲染模型
- `schedule*`：启动副作用，并返回 cleanup
- `get*`：提取或计算单个值
- `pick*`：按优先级从多个候选中择优选择

<!-- more -->

## 一、先说结论：看到名字，就大致知道行为

我希望一段模块代码最终能达到这样一种阅读体验：

```typescript
const view = resolveCheckInBannerView(activity, progress)
const status = resolveCheckInBannerStatusState(view)
const width = getCheckInBannerProgressWidth(view.progressRatio)
const stopRefresh = scheduleCheckInBannerRefresh({ badge: view.badge, refresh })
const rewards = pickRewards(progress, activity.rewardGroups)
```

哪怕你还没点进实现，也能先得到几个稳定判断：

- `resolve*` 大概率是纯函数，可以直接读返回值
- `schedule*` 大概率有副作用，需要考虑生命周期和 cleanup
- `get*` 大概率只是算一个值，不会重塑大结构
- `pick*` 大概率存在“优先级”和“兜底链”

这就是这套规范最核心的价值：**降低读代码时的上下文切换成本**。

## 二、四类前缀的边界

为了避免“名字像在分类，实际上还是靠猜”，边界要尽量硬一点。

| 前缀 | 用途 | 典型返回值 | 是否有副作用 |
|------|------|------------|--------------|
| `resolve*` | 结构性转换，产出 View / State / Entry | 对象、数组、渲染模型 | 无 |
| `schedule*` | 启动定时器、订阅、轮询等 | `() => void` | 有 |
| `get*` | 提取一个值或计算一个派生值 | number、string、boolean、小型数组 | 无 |
| `pick*` | 从多个候选来源中按优先级选择 | 对象、数组、标量 | 无 |

如果一句话概括这四类边界：

- `resolve*` 关心“把数据组织成什么结构供 UI 消费”
- `get*` 关心“从现有结构里拿到什么值”
- `pick*` 关心“多个来源里该选哪个”
- `schedule*` 关心“副作用什么时候启动、怎么停止”

### 1. `resolve*`：组织渲染模型

`resolve*` 用在“把一种数据形状转换成另一种更适合渲染的数据形状”的场景。

```typescript
export function resolveFeatureView(
  config: Config,
  data: DomainData | null,
): IFeatureView | null { ... }

export function resolveFeatureStatusState(
  view: IFeatureView,
): IFeatureStatusState { ... }

export function resolveFeatureEntries(
  params: { level: number; data: DomainData | null },
): IFeatureEntry[] { ... }
```

它的判断标准不是“返回值一定很复杂”，而是：**这个函数是否在重新组织结构，让下游更容易消费**。

所以 `resolveFeatureEntries()` 即使返回数组，也依然属于 `resolve*`。因为它不是简单地“拿一个值”，而是在定义入口结构。

`resolve*` 最适合承担这些事情：

- domain/store -> View
- View -> 子视图状态
- 多段原始数据 -> 页面入口结构

### 2. `schedule*`：启动副作用，并返回 cleanup

只要函数会启动定时器、订阅、轮询、监听器之类的副作用，我倾向于统一命名成 `schedule*`，并要求它**始终返回 `() => void`**。

```typescript
export function scheduleFeatureRefresh({
  deadline,
  refresh,
}: {
  deadline: { remainingSeconds: number | null; autoRefresh: boolean }
  refresh: () => void | Promise<void>
}): () => void {
  if (!deadline.autoRefresh || deadline.remainingSeconds == null || deadline.remainingSeconds <= 0) {
    return () => {}
  }

  const timer = globalThis.setTimeout(() => {
    void refresh()
  }, deadline.remainingSeconds * 1000)

  return () => {
    globalThis.clearTimeout(timer)
  }
}
```

这个约定的好处是，调用方一看到名字和返回值，就知道应该怎么接：

```typescript
let stop = () => {}

watch(
  () => props.someDep,
  (dep) => {
    stop()
    stop = scheduleFeatureX({ dep, refresh })
  },
  { immediate: true },
)

onBeforeUnmount(() => stop())
```

我最看重的是这一点：**函数名把生命周期责任暴露出来了**。调用方不会误以为它只是个普通计算函数。

### 3. `get*`：提取一个值，或计算一个派生值

`get*` 适合做值级别的事情，而不是结构级别的事情。

```typescript
function getCollectedCount(progress: Progress | null, key: string): number {
  return normalizeCount(progress?.collected[key])
}

export function getProgressFillWidth(ratio: number): number {
  const safe = Math.max(0, Math.min(1, ratio))
  return Math.round(MAX_WIDTH * safe)
}

export function getVisibleRewardNames(rewards: RewardItem[]): string[] {
  return rewards
    .filter((reward) => !reward.hidden)
    .map((reward) => reward.name)
}
```

这里有一个容易混淆的点：`get*` 不等于“实现必须非常短”。它也可以包含一点过滤、规范化、格式化逻辑。

真正的区别在于：

- `get*` 的输出通常还是“一个值”或“一个很薄的结果”
- `resolve*` 的输出通常是“一个供后续模块直接消费的结构”

### 4. `pick*`：强调优先级和 fallback 链

`pick*` 不是“另一个名字的 `get*`”，它解决的是另一类问题：**多个候选源之间的选择策略**。

```typescript
function pickRewards(
  progress: Progress | null,
  rewardGroups: Array<{ level: number; items: RewardItem[] }>,
): RewardItem[] {
  const progressRewards = progress?.rewardList ?? []
  if (progressRewards.length > 0) return progressRewards

  const currentLevel = progress?.currentLevel
  if (currentLevel != null) {
    const matched = rewardGroups.find((group) => group.level === currentLevel)
    if (matched?.items.length) return matched.items
  }

  return rewardGroups[0]?.items ?? []
}
```

如果一个函数的重点在于“从哪里拿”，而且“有明确优先级”，那我会更愿意把它命名成 `pick*`，而不是 `get*`。

这样做的好处是，读者会天然预期：

- 里面可能有多段 if / fallback
- 调整业务优先级时，要改这个函数
- 这个函数的测试重点不是计算公式，而是选择顺序

## 三、公开函数怎么命名

公开函数我通常用三段式：

```text
<动词><模块名><名词>
```

例如：

- `resolveCheckInBannerView`
- `resolveCheckInBannerStatusState`
- `scheduleCheckInBannerRefresh`
- `getCheckInBannerProgressWidth`

这个结构有两个实际好处。

第一，读名字时就能快速拆出职责：

- 动词：这个函数做什么
- 模块名：这个函数属于哪个模块
- 名词：这个函数产出的是什么

第二，对大型项目非常友好。只要搜索模块名中缀，例如 `CheckInBanner`，通常就能一次命中该模块的大部分公开 API。

内部辅助函数则没必要强行带模块名前缀，比如：

- `normalizeCount`
- `parseLabel`
- `pickRewards`

前提是它们只在当前文件或当前局部上下文中使用，不打算作为公共入口暴露。

## 四、ViewModel 模块里，哪些东西值得单独拆文件

这部分不是本文的主角，但和命名规范关系很紧，所以简单说一下。

如果一个 UI 模块已经开始出现以下情况：

- 既有 View 组装，又有定时器/轮询
- 既有主视图，又有多个子状态模型
- 组件脚本里塞满了计算、选择、watch 和 cleanup

那么可以考虑按职责拆成几个小文件：

```text
checkInBannerView.ts       # View 接口 + resolveCheckInBannerView
checkInBannerStatus.ts     # resolveCheckInBannerStatusState
checkInBannerProgress.ts   # getCheckInBannerProgressWidth
checkInBannerRefresh.ts    # scheduleCheckInBannerRefresh
checkInBannerState.ts      # resolveCheckInBannerEntries
```

注意，这不是说每个功能都应该拆成 5 个文件。**简单组件不要为规范而规范。**

如果一个组件只是展示两三个字段，只有一两个 `computed`，那把逻辑留在组件内部往往更自然。规范应该帮助我们减少复杂度，而不是制造额外复杂度。

## 五、一个更自洽的完整示例

下面用一个“每日签到横幅”模块演示这套命名方式。这个模块有四类需求：

- 把活动数据转换成横幅 View
- 根据 View 生成状态栏文案
- 计算进度条宽度
- 根据徽章信息调度自动刷新

### 1. 主 View：`resolveCheckInBannerView`

```typescript
import type { ICheckInActivity, ICheckInProgress, IRewardItem } from '@/interfaces/common'

export interface ICheckInBannerMetricView {
  label: string
  current: number
  target: number
}

export interface ICheckInBannerBadgeView {
  iconUrl: string
  remainingSeconds: number | null
  autoRefresh: boolean
}

export interface ICheckInBannerView {
  userName: string
  metrics: ICheckInBannerMetricView[]
  progressRatio: number
  statusText: string
  rewards: IRewardItem[]
  badge: ICheckInBannerBadgeView | null
  isCompleted: boolean
}

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
  rewardGroups: Array<{ level: number; items: IRewardItem[] }>,
): IRewardItem[] {
  const fromProgress = progress?.rewards ?? []
  if (fromProgress.length > 0) return fromProgress

  const currentLevel = progress?.currentLevel
  if (currentLevel != null) {
    const matched = rewardGroups.find((group) => group.level === currentLevel)
    if (matched?.items.length) return matched.items
  }

  return rewardGroups[0]?.items ?? []
}

export function resolveCheckInBannerView(
  activity: ICheckInActivity | null,
  progress?: ICheckInProgress | null,
): ICheckInBannerView | null {
  if (!activity) return null

  const resolvedProgress = progress ?? activity.progress ?? null
  const metricKeys = Object.keys(resolvedProgress?.target ?? {})
    .filter((key) => getTarget(resolvedProgress, key) > 0)

  const metrics: ICheckInBannerMetricView[] = metricKeys.map((key) => ({
    label: key,
    current: getCurrent(resolvedProgress, key),
    target: getTarget(resolvedProgress, key),
  }))

  const total = metricKeys.reduce((sum, key) => sum + getTarget(resolvedProgress, key), 0)
  const done = metricKeys.reduce((sum, key) => sum + getCurrent(resolvedProgress, key), 0)

  const allDone = metricKeys.length > 0 && done >= total
  const hasProgress = done > 0
  const statusText = allDone ? '签到完成' : hasProgress ? '继续加油' : '每日签到领奖励'

  return {
    userName: activity.userName ?? '',
    metrics,
    progressRatio: total > 0 ? Math.min(1, done / total) : 0,
    statusText,
    rewards: pickRewards(resolvedProgress, activity.rewardGroups ?? []),
    badge: activity.badge?.iconUrl
      ? {
          iconUrl: activity.badge.iconUrl,
          remainingSeconds: activity.badge.remainingSeconds,
          autoRefresh: true,
        }
      : null,
    isCompleted: allDone,
  }
}
```

这个文件里同时出现了 `resolve*`、`get*`、`pick*`，它们的分工是清楚的：

- `resolveCheckInBannerView` 负责组装完整 View
- `getCurrent` / `getTarget` 负责值级提取
- `pickRewards` 负责候选奖励的优先级选择

### 2. 子状态：`resolveCheckInBannerStatusState`

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
    .filter((metric) => metric.current < metric.target)
    .map((metric) => `${metric.label} x${metric.target - metric.current}`)

  if (missing.length === view.metrics.length) {
    return { mode: 'pending', text: '每日签到领奖励', missingLabels: [] }
  }

  return { mode: 'progress', text: '还差', missingLabels: missing }
}
```

这类函数依然叫 `resolve*`，因为它做的不是“拿一个值”，而是把 `view` 再组织成一个更适合局部 UI 的状态模型。

### 3. 数值工具：`getCheckInBannerProgressWidth`

```typescript
export const CHECK_IN_BANNER_MAX_FILL_WIDTH = 280

export function getCheckInBannerProgressWidth(ratio: number): number {
  const safe = Math.max(0, Math.min(1, ratio))
  return Math.round(CHECK_IN_BANNER_MAX_FILL_WIDTH * safe)
}
```

这是典型的 `get*`：只关心一个派生值，不关心结构。

### 4. 副作用调度：`scheduleCheckInBannerRefresh`

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

  return () => {
    globalThis.clearTimeout(timer)
  }
}
```

只要看到返回值是 `() => void`，调用方就会自然联想到 cleanup。

### 5. 模块入口：`resolveCheckInBannerEntries`

```typescript
import type { ICheckInActivity, ICheckInProgress } from '@/interfaces/common'
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

虽然这里返回的是数组，但它依然是 `resolve*`，因为它在定义模块入口结构，而不是取一个零散值。

### 6. 组件消费：只依赖 View 和工具函数

```vue
<script setup lang="ts">
import type { ICheckInBannerView } from './checkInBannerView'
import { computed, onBeforeUnmount, watch } from 'vue'
import { getCheckInBannerProgressWidth } from './checkInBannerProgress'
import { scheduleCheckInBannerRefresh } from './checkInBannerRefresh'
import { resolveCheckInBannerStatusState } from './checkInBannerStatus'

const props = defineProps<{
  view: ICheckInBannerView
  onRefresh?: () => void | Promise<void>
}>()

const status = computed(() => resolveCheckInBannerStatusState(props.view))
const fillWidth = computed(() => getCheckInBannerProgressWidth(props.view.progressRatio))

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
  stopRefresh()
})
</script>

<template>
  <div class="check_in_banner">
    <div class="progress_fill" :style="{ width: `${fillWidth}px` }" />
    <span :class="`status_text is-${status.mode}`">{{ status.text }}</span>

    <span v-for="item in status.missingLabels" :key="item" class="missing_tag">
      {{ item }}
    </span>

    <img
      v-if="props.view.badge"
      :src="props.view.badge.iconUrl"
      class="badge_icon"
    />
  </div>
</template>
```

这个例子里，组件层的职责很清楚：

- 收到 `view`
- 调 `resolve*` 处理子状态
- 调 `get*` 取派生值
- 调 `schedule*` 管理副作用

组件不需要知道 domain 数据的原始结构，也不需要自己拼装复杂业务逻辑。

## 六、接口和文件命名，只需要保持一致

接口和文件命名没有必要搞成一整套复杂规则，但最好保持稳定。

### 接口

如果团队习惯使用 `I` 前缀，可以这样约定：

| 元素 | 示例 |
|------|------|
| View 接口 | `ICheckInBannerView` |
| View 子结构 | `ICheckInBannerBadgeView` |
| 状态接口 | `ICheckInBannerStatusState` |
| 入口类型 | `ICheckInBannerEntry` |

如果团队本来就不用 `I` 前缀，也没必要为了这篇文章强行改风格。这里真正重要的是后缀一致性，比如 `*View`、`*State`、`*Entry`。

### 文件

文件名最好直接对应它暴露的核心概念：

```text
checkInBannerView.ts
checkInBannerStatus.ts
checkInBannerProgress.ts
checkInBannerRefresh.ts
checkInBannerState.ts
```

这样做的好处是，读目录时就能大致知道每个文件负责哪一层。

## 七、什么时候不要过度使用这套规范

这是我觉得原本最容易被忽略的一点。

这套命名规范适合：

- 逻辑比较厚的 UI 模块
- 组件已经出现多个派生状态
- 有副作用需要统一清理
- 需要把 store/domain 和组件层解耦

这套命名规范不一定适合：

- 非常简单的展示组件
- 一次性页面代码
- 只有一两个字段映射的小模块

如果一个组件只有几十行，只有一个 `computed`，为了“规范”硬拆出 `view.ts`、`state.ts`、`progress.ts`，反而会让代码更碎。

经验上我会这样判断：

- 复杂度还低时，先别拆
- 当组件里已经开始同时出现“数据组装 + 状态派生 + 副作用”时，再引入这套约定

## 八、补充：`stop*` 适合作为局部辅助命名

我现在不会把 `stop*` 放进“四大核心前缀”里，但它依然是一个很实用的补充命名。

例如：

```typescript
export function stopCheckInBannerClick(event: { stopPropagation: () => void }) {
  event.stopPropagation()
}
```

这类函数通常很短，适合用在下面这些场景：

- 给阻止事件的行为起一个明确名字
- 避免在模板里塞内联箭头函数
- 让模板读起来更接近业务语义

之所以把它放在补充位置，是因为它不像 `resolve*`、`schedule*`、`get*`、`pick*` 那样，能构成一套完整的模块职责分类。它更像一个局部命名习惯。

## 九、总结

如果只保留一条最有用的判断规则，那就是：

**调用方需要自己管理 cleanup 的函数，用 `schedule*`；调用方只需要拿返回值继续渲染的函数，用 `resolve*`、`get*` 或 `pick*`。**

再细一点说：

- `resolve*` 负责把数据组织成可消费的结构
- `get*` 负责拿一个值
- `pick*` 负责按优先级选一个结果
- `schedule*` 负责启动和停止副作用

命名规范的价值，从来不在于“统一单词”，而在于**把职责信息提前暴露在名字里**。这样新人接手模块时，先看 import 列表就能知道哪些函数值得放心组合，哪些函数需要小心管理生命周期。
