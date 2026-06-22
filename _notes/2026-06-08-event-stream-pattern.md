---
layout: post
title: "一个 Promise，两个世界：EventStream 的旁路通道设计"
date: 2026-06-08
category:
tags: [TypeScript, Design Patterns, Async, Event Stream, Promise]
---

如果你写过 AI 应用的 streaming 响应处理，你一定遇到过这个矛盾：SSE 或 WebSocket 是推送模型，事件到达就抛给你；但你的业务代码是拉取模型，想用 `for await` 逐个消费。如何在两种模型之间搭一座桥？

我在阅读 [pi](https://github.com/earendil-works/pi-mono) 的源码时，看到了一个不到 80 行的实现，干净利落地解决了这个问题。这篇博客把它拆开来讲。

<!-- more -->

## 问题的核心

假设你有一个 LLM provider 在处理 streaming 响应。每个 chunk 解析成一个事件：

```typescript
// 推送侧 —— provider 解析 SSE chunk
stream.push({ type: "text_delta", delta: "Hello", partial: msg });
stream.push({ type: "text_delta", delta: " world", partial: msg });
stream.push({ type: "done", reason: "stop", message: completeMessage });
```

你希望消费者能这样消费：

```typescript
// 拉取侧 —— 业务代码
for await (const event of stream) {
  if (event.type === "text_delta") render(event.delta);
  if (event.type === "done") break;
}
// 循环结束后，拿到完整的 AssistantMessage
const message = await stream.result();
```

这里有个隐藏问题：**`for await` 迭代结束 ≠ 拿到最终结果**。`done` 事件只是迭代器返回了，但你需要的完整 `AssistantMessage` 怎么取？

## 方案一（不可行）：塞进 iterator 的 value

TypeScript 的 `IteratorResult` 协议规定：`done: true` 时 `value` 应该是 `undefined`。违反协议会破坏类型安全，IDE 也帮不了你。

## 方案二：EventStream 的旁路通道

核心思路：**让流有两套输出通道**。

| 通道 | 消费者接口 | 交付内容 |
|------|-----------|---------|
| 迭代通道 | `for await (const event of stream)` | 逐事件增量（text_delta, thinking_delta...） |
| 结果通道 | `await stream.result()` | 聚合最终结果（AssistantMessage） |

同一个 `done` 事件到达时，同时触发两个通道：

```
push({ type: "done", message: completeMessage })
  │
  ├─→ 迭代通道: yield { type: "done" } → iterator 返回
  │
  └─→ 结果通道: resolveFinalResult(completeMessage)
```

## 关键技巧：提前捕获 Promise 的 resolve

```typescript
class EventStream<T, R> {
  private finalResultPromise: Promise<R>;
  private resolveFinalResult!: (result: R) => void;

  constructor(isComplete, extractResult) {
    // Promise 在此创建，但 resolve 被"偷"出来存为实例方法
    this.finalResultPromise = new Promise((resolve) => {
      this.resolveFinalResult = resolve;
    });
  }

  push(event: T): void {
    if (this.isComplete(event)) {
      this.done = true;
      this.resolveFinalResult(this.extractResult(event)); // 此刻决议
    }
    // ... 入队或交付
  }

  result(): Promise<R> {
    return this.finalResultPromise;
  }
}
```

Promise 的**创建**和**决议**在时间上完全分离：
- 构造时创建 Promise，但 `resolve` 不调用，Promise 保持 `pending`
- 生产者调用 `push()` 的某一刻，`resolve` 被调用，Promise `fulfilled`
- 消费者 `await stream.result()` 随时可调用——如果 Promise 已决议，立即返回；如果还没，就等

## 另一个关键：queue + waiting 的双缓冲

```typescript
private queue: T[] = [];                          // 事件缓存
private waiting: ((result: IteratorResult<T>) => void)[] = [];  // 消费者等待队列

push(event: T): void {
  const waiter = this.waiting.shift();
  if (waiter) {
    waiter({ value: event, done: false });  // 消费者在等 → 直接给
  } else {
    this.queue.push(event);                  // 消费者没在等 → 先存着
  }
}

async *[Symbol.asyncIterator]() {
  while (true) {
    if (this.queue.length > 0) {
      yield this.queue.shift()!;             // 有缓存 → 直接 yield
    } else if (this.done) {
      return;                                // 没缓存且结束了 → 终止
    } else {
      const result = await new Promise(r => this.waiting.push(r));
      if (result.done) return;
      yield result.value;                   // 没缓存且没结束 → 等待生产者
    }
  }
}
```

任何时候，要么消费者在等生产者，要么生产者已经把事件存好了。**永远不会双方同时等待**——因为 `push()` 和 `yield` 共享同一个事件循环的调度，不会产生死锁。

## 这个设计的优势

### 1. 类型安全，不妨害迭代器协议

迭代通道严格遵守 `AsyncIterable` 协议。结果通道是独立的方法，返回 `Promise<R>`，不需要 hack 迭代器的 `value` 字段。

### 2. 关注点分离

消费者代码中，渲染逻辑和业务逻辑可以分开处理：

```typescript
// 渲染层：只关心增量事件
function renderStream(stream: AssistantMessageEventStream) {
  for await (const event of stream) {
    if (event.type === "text_delta") appendToUI(event.delta);
  }
}

// 业务层：只关心最终结果
async function processMessage(stream: AssistantMessageEventStream) {
  const message = await stream.result();
  saveToHistory(message);
  checkToolCalls(message);
}
```

两者可以并发执行——`for await` 在消费，另一个 async 函数在 `await stream.result()`，它们之间不需要任何协调代码。

### 3. 无锁、无复杂状态机

`queue` 和 `waiting` 两个数组就是全部状态。没有 `EventEmitter` 的注册/注销管理，没有 RxJS 的 operator 链。代码量少到可以一眼看到全部行为。

### 4. 天然支持背压

如果生产者 push 的速度快于消费者 yield 的速度，事件会堆积在 `queue` 中。你可以根据 `queue.length` 实现流量控制——只需在 `push()` 中加一行判断。

### 5. 终态检测内置于协议

`isComplete` 回调让**事件本身**定义什么是终点，而不是外部强加一个“结束”信号。这样做的好处是：`push()` 调用者不用关心"我是不是该调用 `end()` 了"，只要事件类型是 `done` 或 `error`，流自动关闭。

## 如何学习这类设计

这个设计看起来精妙，但拆开来看，每一块都是基础概念：

1. **Promise 的 resolve 提前捕获**：`new Promise(resolve => this.resolver = resolve)` 是个常用技巧，在需要"外部决议 Promise"的场景中反复出现。熟记这行代码。

2. **生产者-消费者缓冲**：如果你学过操作系统中的 producer-consumer problem 或者 Go 的 buffered channel，这个 `queue + waiting` 双缓冲是同一回事的简化版。

3. **迭代器协议**：读 MDN 上 `Symbol.asyncIterator` 的文档，理解 `IteratorResult` 的 `{ value, done }` 结构，然后尝试用 `async function*` 实现一个简单的异步序列。

4. **阅读高质量的流式处理代码**：除了 `EventStream`，还可以看 Node.js 的 `Readable.from()` 实现、RxJS 的 `Subject`、或者 Deno 的 `std/async/deferred.ts`。

5. **手写实现**：最有效的学习方式是自己写一遍。找一个类似场景——比如把 WebSocket 的消息流适配成 `for await`——然后自己实现一个最小版本。写完再回头看 `EventStream`，你会发现每个细节都有其用意。

## 总结

`EventStream` 的优雅在于它没有发明新概念。`Promise`、`async function*`、`Array.shift()`——全是语言内置。它只是用一种特别干净的方式把它们组合起来了。

当你下一次需要在推送和拉取模型之间架桥时，不需要引入 RxJS 或 EventEmitter，记住这个范式就够了：**用 Promise 做旁路通道，用 queue 做缓冲，用 async iterator 做消费接口**。

---

*本文分析的代码来自 [pi 项目的 `packages/ai/src/utils/event-stream.ts`](https://github.com/earendil-works/pi-mono)。*
