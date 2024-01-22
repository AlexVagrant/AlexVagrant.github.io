---
layout: post
title: "git autocrlf 解决 obsidian windows macos git 同步冲突问题"
date: 2024-01-22 
category: git
tags: 
---

### 问题场景
obsidian 在使用 git 插件进行同步的时候， Windows 和 macOS 系统通常会出现大量的冲突。而这些冲突最根本的原因就是两个系统之间换行符不一致的问题。

### 问题原因
Windows 系统使用回车和换行 两个字符来结束一行，而在 Linux 和 macOS 系统中只使用换行一个字符。

### 解决方案

#### windows 解决方案 
git 提供了 `autocrlf` 配置来解决这个问题。

`git config --global core.autocrlf true`

将文件提交到暂存区时 `autocrlf` 可以自动将 CRLF 转换为 LF。当迁出代码（可以理解为将远端的代码拉到本地）的时候，git 会进行反向操作将 LF 转化为 CRLF。原文如下：

> Git can handle this by auto-converting CRLF line endings into LF when you add a file to the index, and vice versa when it checks out code onto your filesystem. You can turn on this functionality with the core.autocrlf setting. If you’re on a Windows machine, set it to true — this converts LF endings into CRLF when you check out code:

#### Linux 或者 macOS 解决方案 
如果是在Linux 或者 macOS 系统上，希望git自动处理迁出代码中意外的 CRLF 。需要做如下设置 

`git config --global core.autocrlf input`


### 参考链接
- [git自定义配置文档](https://git-scm.com/book/en/v2/Customizing-Git-Git-Configuration)
