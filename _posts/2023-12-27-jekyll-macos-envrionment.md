---
layout: post
title:  "macos jekyll 环境配置"
date: 2023-12-27
category: bolg
tags: [blog]
---

最近换了新的电脑，jekeyll 环境需要重新配置。macos 自带的 ruby 版本是 `2.6.*`，这个版本安装依赖会有各种问题需要对 ruby 进行升级。

按照[jekyll官网](https://jekyllrb.com/docs/installation/macos/)的步骤升级到 `3.1.*` 即可


### 1 安装 Homebrew

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 2 通过 Homebrew 安装 chruby 和 ruby-install

```sh
brew install chruby ruby-install xz
```

通过 ruby-install 安装 ruby `3.1.3` 版本

```sh
ruby-install ruby 3.1.3
```

配置 shell 自动使用 chruby

```sh
echo "source $(brew --prefix)/opt/chruby/share/chruby/chruby.sh" >> ~/.bashrc
echo "source $(brew --prefix)/opt/chruby/share/chruby/auto.sh" >> ~/.bashrc
echo "chruby ruby-3.1.3" >>  ~/.bashrc
```

检查 ruby 是不是安装正确

```shell
ruby -v
```

### 3 安装 jekyll

```shell
gem install jekyll
```

