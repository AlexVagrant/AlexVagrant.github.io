---
layout: post
title: "修复 Metro SHA-1 错误：react-native-worklets Bundle Mode 补丁指南"
date: 2026-05-11
category:
tags: [React Native, Metro, Expo, iOS]
---

启动 `private-mind` 项目的 iOS 构建时，Metro 报出以下错误，导致打包失败：

```
Failed to get the SHA-1 for:
/Users/.../node_modules/react-native-worklets/.worklets/2830240121133.js
```

本文记录该错误的根因和官方推荐的修复方案。

<!-- more -->

## 背景

`react-native-worklets` 是 `react-native-reanimated` 生态中的一个包，提供 Bundle Mode 能力。`private-mind` 项目通过 `react-native-streamdown` 间接依赖了它，并在 `babel.config.js` 中启用了：

```js
['react-native-worklets/plugin', { bundleMode: true }]
```

Bundle Mode 下，worklets 插件会在 `node_modules/react-native-worklets/.worklets/` 目录中动态生成 JS 文件。Metro 打包时先解析这些文件路径，再去计算 SHA-1 哈希——但在这两步之间，worklets 插件可能已经重新生成了文件。Metro 发现文件"消失了"，于是抛错。

这个问题的实质是 **Metro 文件监听器 + worklets 动态生成之间的竞态条件**。

## 官方修复方案

`react-native-worklets` 仓库提供了针对 Metro 和 metro-runtime 的补丁文件：

- [Bundle Mode Patches](https://github.com/software-mansion/react-native-reanimated/tree/main/packages/react-native-worklets/bundleMode/patches)

`private-mind` 使用的 metro 版本是 **0.83.7**，最接近的官方补丁是 **0.83.2**。小版本兼容，直接应用即可。

### 1. 确认 metro 版本

```bash
yarn why metro | grep "metro@npm"
```

输出两行，其中一行是 Expo 引入的：

```
metro@npm:0.83.7, metro@npm:^0.83.3
```

### 2. 给 metro 打补丁

```bash
yarn patch metro@npm:0.83.7
```

记下输出的临时目录路径（例如 `/private/var/folders/.../user/XXXXX`），编辑其中的 `src/node-haste/DependencyGraph.js`，在 `getOrComputeSha1` 方法内 return 之前插入：

```js
if (mixedPath.includes("react-native-worklets/.worklets/")) {
  const createHash = require("crypto").createHash;
  return {
    sha1: createHash("sha1")
      .update(performance.now().toString())
      .digest("hex"),
  };
}
```

这段代码的作用：当 Metro 尝试计算 `.worklets/` 下文件的 SHA-1 时，直接返回一个基于 `performance.now()` 生成的虚拟哈希，跳过文件系统读取——从而避免了文件被删除导致的错误。

保存后提交补丁：

```bash
yarn patch-commit -s <临时目录路径>
```

`yarn` 会将补丁写入 `.yarn/patches/`，并自动在 `package.json` 中添加 `resolutions` 条目。

### 3. 给 metro-runtime 打补丁

```bash
yarn patch metro-runtime@npm:0.83.7
```

编辑 `src/modules/HMRClient.js`，在 `inject` 函数体开头（`if (global.globalEvalWithSourceUrl)` 之前）插入：

```js
if (global.__workletsModuleProxy?.propagateModuleUpdate) {
  global.__workletsModuleProxy.propagateModuleUpdate(code, sourceURL);
}
```

这个补丁确保 Fast Refresh 时 worklets 模块变更能正确通过 proxy 传播。

保存并提交：

```bash
yarn patch-commit -s <临时目录路径>
```

### 4. 清理缓存并重启

```bash
rm -rf node_modules/react-native-worklets/.worklets/*
npx expo start --clear
```

## 总结

| 步骤 | 包名 | 作用 |
|------|------|------|
| 1 | metro | 跳过 `.worklets/` 文件的 SHA-1 计算，消除竞态报错 |
| 2 | metro-runtime | 让 Fast Refresh 正确更新 worklets 模块 |
| 3 | 清缓存 | 清除旧的 worklets 生成文件，从干净状态开始 |

完成后 iOS 构建应能正常通过。

## 参考

- [react-native-worklets Bundle Mode Patches](https://github.com/software-mansion/react-native-reanimated/tree/main/packages/react-native-worklets/bundleMode/patches)
