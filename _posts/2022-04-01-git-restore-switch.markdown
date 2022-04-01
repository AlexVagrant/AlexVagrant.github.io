---
layout: post
title: Git restore 和 Git switch 基本API使用 二
date: 2021-04-01 20:10:00 GMT+0800
categories: git
tag: git restore switch
---

<image src="/assets/images/git_restore_switch.png"/>
 
<br/>
<hr/>
<br/>


## 新的命令
  2019年7月10号[gitster]将`nd/switch-and-restore`合并到了master，从而为我们带来了两个新的git命令：`git restore`、`git switch`。git 版本: 2.23.0。

  `git restore`、`git switch`主要是为了拆分`git checkout`命令承担的`分支操作`、`文件恢复操作`功能，简化开发者对于git命令的理解


  更详细的信息，请点击链接查看: [Merge branch 'nd/switch-and-restore']


## git restore