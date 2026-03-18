---
layout: post
title: "MacOS 中配置 Lazygit 结合 Claude Code 自动生成 Git Commit 消息"
date: 2026-03-02
category: 工具配置
tags: [lazygit, claude-code, git, macos]
---

> 本文介绍如何在 macOS 中配置 Lazygit，使其能够结合 Claude Code 自动生成符合规范的 commit 消息。

# MacOS 中配置 Lazygit 结合 Claude Code 自动生成 Git Commit 消息

## 前言

在日常开发工作中，写 Git commit 消息是一项既繁琐又重要的任务。一个好的 commit 消息能够帮助团队更好地理解代码变更的历史。本文将介绍如何在 macOS 中配置 Lazygit，使其能够结合 Claude Code 自动生成符合规范的 commit 消息。

## 环境说明

- 操作系统：macOS
- 终端工具：iTerm2 / Terminal
- 版本控制工具：Lazygit
- AI 助手：Claude Code (claude)

## 配置步骤

### 第一步：确认 Lazygit 配置文件路径

Lazygit 的配置文件位于以下路径：

```
~/Library/Application Support/lazygit/config.yml
```

如果该目录或文件不存在，请先创建：

```bash
mkdir -p ~/Library/Application\ Support/lazygit
touch ~/Library/Application\ Support/lazygit/config.yml
```

### 第二步：配置自定义命令

编辑 Lazygit 配置文件，添加一个自定义命令来调用 Claude Code 生成 commit 消息。

打开配置文件：

```bash
nvim ~/Library/Application\ Support/lazygit/config.yml
```

添加以下内容：

```yaml
customCommands:
  - key: 'C'
    context: 'files'
    description: 'Generate commit message with Claude Code'
    command: >-
      sh -c "git diff --staged --quiet && echo 'No staged changes' ||
      (git diff --staged | ~/.local/bin/claude -p 'Generate a concise git commit message for these staged changes. Output ONLY the raw commit message with no markdown, no code blocks, no backticks, no explanations. Use conventional commit format.' --model sonnet --output-format text > /tmp/commit_msg && git commit -F /tmp/commit_msg)"
    output: 'terminal'
```

### 配置参数说明

| 参数 | 说明 |
|------|------|
| `key` | 快捷键绑定，设置为 `C` 表示可以直接按 `C` 键触发命令 |
| `context` | 执行命令的上下文，`files` 表示在文件视图下可用 |
| `description` | 命令描述，会在 Lazygit 界面中显示 |
| `command` | 要执行的命令内容 |
| `output` | 输出方式，`terminal` 表示结果输出到终端 |

### 命令详解

```bash
sh -c "git diff --staged --quiet && echo 'No staged changes' ||
(git diff --staged | ~/.local/bin/claude -p 'Generate a concise git commit message for these staged changes. Output ONLY the raw commit message with no markdown, no code blocks, no backticks, no explanations. Use conventional commit format.' --model sonnet --output-format text > /tmp/commit_msg && git commit -F /tmp/commit_msg)"
```

各部分作用：
1. `git diff --staged --quiet && echo 'No staged changes'` - 检查是否有已暂存的更改，无则直接提示不再往下执行
2. `(git diff --staged | ...)` - 有暂存更改时，将 diff 传给 Claude Code 生成 commit 消息
3. `~/.local/bin/claude -p "..."` - 将 diff 传给 Claude Code 生成 commit 消息
4. `--model sonnet` - 使用 sonnet 模型
5. `--output-format text` - 输出纯文本格式
6. `> /tmp/commit_msg` - 将结果保存到临时文件
7. `git commit -F /tmp/commit_msg` - 使用文件内容作为 commit 消息完成提交

### 第三步：使用方式

1. 在 Lazygit 中暂存需要提交的文件（按 `space` 键）
2. 直接按 `C` 键触发命令
3. 等待 Claude Code 分析代码变更并生成消息
4. 命令会自动执行 `git commit`

如果你使用的是绝对路径而不是 `~/.local/bin/claude`，需要先确认 `claude` 命令的位置：

```bash
# 检查 claude 命令位置
which claude
```

常见路径包括：
- `~/.local/bin/claude`
- `/usr/local/bin/claude`
- Homebrew 安装路径

## 注意事项

1. **Claude Code 安装路径**：配置使用了路径别名 `~/.local/bin/claude`，确保该路径在你的 `PATH` 中或替换为实际绝对路径
2. **模型选择**：默认使用 sonnet 模型。如需更快响应可改为 `--model haiku`，如需最高质量可改为 `--model opus`
3. **暂存检查**：命令会先检查是否有已暂存的更改，无则提示 "No staged changes" 而不会报错

## 常见问题

### Q: 命令执行失败怎么办？

A: 检查以下几点：
- 确认 Claude Code 是否正确安装：运行 `claude --version`
- 检查 API Key 是否配置正确
- 查看 Lazygit 的错误日志

### Q: 生成的 commit 消息不符合预期？

A: 可以调整 prompt 提示词，使其更符合团队的 commit 规范。

## 总结

通过以上配置，你可以轻松地在 Lazygit 中集成 Claude Code 来自动生成高质量的 Git commit 消息。这不仅节省了时间，还能确保 commit 消息的一致性和规范性。

如果你在使用过程中遇到任何问题，欢迎在评论区留言讨论。
