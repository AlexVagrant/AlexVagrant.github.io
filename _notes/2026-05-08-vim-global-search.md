---
layout: post
title: "Vim 原生全局搜索：vimgrep、grep 与 quickfix 工作流"
date: 2026-05-08
category:
tags: [Vim, CLI]
---

在项目中按关键字搜索所有文件是一个高频需求。很多人的习惯是切到终端跑 `grep`，再记下文件名和行号切回编辑器打开。其实 Vim 内置了完整的项目搜索能力，配合 quickfix 窗口可以实现纯键盘的高效工作流。

<!-- more -->

## 一、`:vimgrep` —— Vim 内置搜索

`vimgrep` 是 Vim 自家的搜索实现，不依赖外部工具，跨平台行为一致。

```vim
:vimgrep /pattern/ **/*.py          " 递归搜索所有 .py 文件

:vimgrep /TODO/ ** | copen          " 搜索并打开 quickfix 结果窗口

:vimgrep /\cError/ src/**/*.rs      " \c 忽略大小写
```

- **优点**：用 Vim 正则引擎，所有平台一致
- **缺点**：大项目中比 `grep` 慢

## 二、grep —— 命令行文本搜索利器

`grep`（Global Regular Expression Print）是 Unix 系统中搜索文本的标准工具，1974 年由 Ken Thompson 从 `ed` 编辑器抽出。几乎所有的 Linux / macOS 系统都预装了它。

### 基本语法

```bash
grep [选项] "pattern" 目标文件或目录
```

如果没有指定文件，`grep` 默认读取标准输入。

### 常用选项

| 选项 | 含义 |
|------|------|
| `-i` | ignore case，忽略大小写 |
| `-r` | recursive，递归搜索子目录 |
| `-n` | line number，显示行号 |
| `-v` | invert match，反向匹配，显示不包含 pattern 的行 |
| `-l` | files-with-matches，只输出匹配到的文件名 |
| `-c` | count，输出每个文件的匹配行数 |
| `-w` | word regexp，只匹配完整单词 |
| `-H` | with-filename，始终输出文件名（多文件时默认开启） |
| `-A N` | after context，显示匹配行后 N 行 |
| `-B N` | before context，显示匹配行前 N 行 |
| `-C N` | context，显示匹配行前后各 N 行 |
| `--include=*.py` | 只搜索匹配 glob 的文件 |
| `--exclude=*.min.js` | 排除匹配 glob 的文件 |

### 正则引擎

`grep` 支持三种正则模式：

```bash
grep "a.*b" file.txt       # 默认：基础正则 BRE
grep -E "a.*b" file.txt    # -E：扩展正则 ERE（支持 +、?、|、()）
egrep "a.*b" file.txt      # egrep 等价于 grep -E
grep -P "a.*b" file.txt    # -P：Perl 兼容正则 PCRE（macOS 默认 BSD grep 不支持）
```

ERE 和 PCRE 是日常开发中最常用的。如果你习惯了 JavaScript 或 Python 的正则，用 `-E` 最为接近；`-P` 在 GNU grep / Linux 上功能更全。

### 实际示例

```bash
grep -rn "TODO" src/                        # 递归搜 TODO，显行号

grep -rnw "main" src/                       # 只匹配完整单词 main

grep -rni "error" --include="*.log" /var/   # 只搜 .log 文件，忽略大小写

grep -rn -C 2 "function handleSubmit" src/  # 显示匹配行前后各 2 行

grep -rl "deprecated" src/                  # 只列出包含 deprecated 的文件名

find . -name "*.js" | xargs grep "import"   # 结合 find 和 xargs 精确控制文件范围

git grep "pattern"                          # 在 Git 仓库中搜索（自动排除 .gitignore 内容）
```

## 三、Vim 中的 `:grep`

Vim 的 `:grep` 通过 `grepprg` 选项调用外部 grep 程序，结果自动填入 quickfix 列表。

在 Vim 中直接使用：

```vim
" 基本用法
:grep "pattern" *.py
:grep -rn "fn main" src/
:grep -irn "error" src/ | copen

" Vim 会把 $* 替换为你的搜索参数
:grep -rnw "class User" app/models/
```

### `grepprg` 配置

用 `set grepprg?` 查看当前设置。一个经典默认值：

```vim
set grepprg=grep\ -n\ $*\ /dev/null
```

`/dev/null` 是一个老技巧：让 `grep` 即使只搜一个文件也强制输出文件名，确保 Vim 能正确解析 quickfix 条目。不过在某些 shell 或 Vim 版本下会触发 `E488: Trailing characters`，改用 `-H` 更可靠：

```vim
set grepprg=grep\ -nH\ $*
```

## 四、接入 ripgrep

[ripgrep](https://github.com/BurntSushi/ripgrep) 比系统 grep 快得多，`--vimgrep` 让输出直接兼容 Vim quickfix：

```vim
" 添加到 ~/.vimrc
set grepprg=rg\ --vimgrep\ --smart-case
set grepformat=%f:%l:%c:%m
```

这两行需要写在 `~/.vimrc` 中，之后 `:grep` 就会自动用 ripgrep。

## 五、结果导航

搜索结果会填入 quickfix 列表：

```vim
:copen          " 打开 quickfix 窗口
:cnext          " 跳转到下一个匹配
:cprev          " 上一个匹配
:cnfile         " 当前文件后，下一个文件的首个匹配
```

## 六、当前文件内搜索

```vim
/pattern        " 向下搜索
?pattern        " 向上搜索
n / N           " 下一个 / 上一个匹配
*               " 搜索光标下的单词（向下）
#               " 搜索光标下的单词（向上）
:g/pattern/p    " 打印所有匹配行
```

## 七、常见误区

### 1. 用 vim 搜索写法去写 grep

vim 里 `/pattern/` 的 `/` 是搜索模式分隔符，但 `:grep` 会把它当作**字面字符**去匹配。也就是说：

```vim
" 错误 — grep 在文件里找 "/priorityOrder/"（带斜杠的字面量）
:grep /priorityOrder/ src/**

" 正确 — grep 只匹配 priorityOrder
:grep priorityOrder src/**
```

`vimgrep` 用 `/pattern/` 语法没错，因为它内建了 vim 的正则解析；`grep` 是外部命令，不是你写什么它都认得。从 `vimgrep` 切到 `:grep` 时最容易犯这个错。

### 2. `**` 递归 glob 需要 shell 配合

Bash 默认**不**启用 `**` 递归匹配，需要先开 `globstar`：

```bash
shopt -s globstar          # 启用 **
grep -rn priorityOrder src/**
```

如果不开启，`**` 只会匹配当前层级，不会递归子目录。

更稳妥的做法是直接用 `grep` 自带的 `-r` 遍历目录，不依赖 shell glob：

```bash
grep -rn priorityOrder src/
```

或者用 `--include` 过滤文件类型：

```bash
grep -rn priorityOrder src/ --include='*.js'
```

### 3. 想让 grep 结果直接弹出 copen？

`:grep` 只会把结果填入 quickfix 列表，不会自动打开窗口。加 `| copen` 就行：

```vim
:grep priorityOrder src/** | copen
```


