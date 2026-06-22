---
layout: post
title: "wsl安装ruby"
date: 2024-11-10
category: wsl
tags: [wsl, ruby]
---

## 1. 在 WSL 上安装 Ruby 3.1.0
   使用 rbenv 来安装 Ruby 3.1.0，这样方便管理和切换不同的 Ruby 版本。

### 安装 rbenv 和依赖项

```bash
# 更新包列表
sudo apt update
# 安装 rbenv 和 Ruby 构建依赖项
sudo apt install -y rbenv build-essential libssl-dev zlib1g-dev libreadline-dev libyaml-dev libxml2-dev libxslt1-dev autoconf bison

```

### 安装 Ruby 3.1.0
使用 rbenv 安装 Ruby 3.1.0 版本，并将其设置为默认版本：

```bash
rbenv install 3.1.0
rbenv global 3.1.0
```
### 验证 Ruby 安装
运行以下命令，确保 Ruby 已正确安装：

```bash
ruby -v
# 输出应为 ruby 3.1.0
```
## 2. 配置 RubyGems 安装路径

将 Ruby 的 gem 安装路径设置为用户主目录下，避免权限问题：

```bash
echo '# Install Ruby Gems to ~/.gem' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/.gem"' >> ~/.bashrc
echo 'export PATH="$HOME/.gem/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 3. 安装 Bundler 和 Jekyll

### 安装 Bundler 和 Jekyll
```bash
gem install bundler jekyll
```

### 验证安装
使用以下命令确认 Bundler 和 Jekyll 已安装成功：

```bash
bundler -v
jekyll -v
```