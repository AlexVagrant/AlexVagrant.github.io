---
layout: post
title: "pnpm 源码调试"
date: 2024-05-11
category: pnpm
tags: [pnpm, debugger, vscode]
---

<image src="/assets/images/pnpm_4.png"/>

### 背景

最近需要开发一下新的脚手架，用来满足日常的业务开发诉求，解决一些繁琐的操作问题。想通过学习 `pnpm` 的架构帮助我更好的实现脚手架的功能。

pnpm架构学习主要参考了**《面试官：pnpm 那么流行，知道它的源码架构实现吗？🤡》**[^1]。这篇文章对于帮助我理解 `pnpm` 的整体架构很有帮助。

但对于 `pnpm` 具体功能的实现并没有详细介绍，所以需要我自己去阅读源码并理解原理。

### 前期准备

`pnpm` 调试主要参考**《pnpm 源码结构及调试指南》**[^2]。自己调试通顺了之后在博客上再记录一遍。

1. 因为项目之间相互依赖需要子包的编译结果作为项目启动的支撑，需要先对 pnpm 项目整体进行一次编译，执行`pnpm run compile` 命令。

2. 修改`pnpm`入口文件的引用,文件路径是`pnpm/pnpm/bin/pnpm.cjs`。

   注释掉23行，打开26行注释。

   23行引用的是 `dist` 目录下的内容，是完全编译后的产物，和源代码没有直接关联，不能用于 `debugger`。

   改为引用 `lib` 目录下的内容，因为含有 `sourceMap` 所以可以直接用于调试源代码。

   <image src="/assets/images/pnpm_1.jpeg"/>

#### pnpm项目调试步骤

1. 添加调试端点。

   <image src="/assets/images/pnpm_2.jpeg"/>

2. 在任意测试项目中运行 `node ~/path/to/pnpm/pnpm install`

   这里需要注意需要在 `pnpm` 项目的环境下使用 `vscode` `javascript Debug Terminal` 运行

   注意下图中红框框出来的部分

   <image src="/assets/images/pnpm_3.jpg"/>

### 参考文章

[^1]: [面试官：pnpm 那么流行，知道它的源码架构实现吗？🤡](https://juejin.cn/post/7358336719165128756)
[^2]: [pnpm 源码结构及调试指南](https://juejin.cn/post/7075584391522713613)
