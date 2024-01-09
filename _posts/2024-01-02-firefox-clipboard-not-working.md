---
layout: post
title: "Firefox 粘贴版无法使用"
date: 2024-01-02
category: clipboard
tags: [Firefox, clipboard] 
---

在使用 Firefox 时会出现无法复制到粘贴版的问题。

地址栏输入`about:config` 进入高级配置首选项页面

将高级配置首选项`dom.events.asyncClipboard.clipboardItem`设置为`true`可以启用此功能。
