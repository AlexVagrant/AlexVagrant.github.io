---
layout: post
title: Git restore 和 Git switch 基本API使用 二
date: 2022-04-01 20:10:00 GMT+0800
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

`git restore` 会根据不同的命令行参数，工作区的内容恢复到不同的版本上。

我这里只介绍了四个常用的命令，这些命令可以覆盖平常git恢复中的80%场景，希望通过这些命令帮助大家加深git操作的理解和对git使用，温故知新。

接下来我们会看到不同的命令行参数对于恢复工作区内容有何差别。

### source

`git restore --source` 必须指定恢复参照源，如果不指定恢复参照源执行命令时git会提示`error: option `source' requires a value`, 可以使用一下三类作为恢复参照源：
- commit
- branch
- tag

commit 指定的恢复参照源是最全面的，可以跨分支使用。例如：当前工作分支是`develop`,想将文件恢复到`master`某个`commit`中文件状态可以直接在`develop`分支如下操作`git restore —source a8aee0f`(a8aee0f 是master的最后一次commit)

branch 如果没有明确指定则是目标分支的最后一次commit，也可以指定目标分支的具体`commit`，例如：`git restore —source master~2 index.html`

tag 相对理解比较简单，文件/路径 恢复到指定`tag`的状态上 例子：`git restore —source v0.2 .`


- 新旧命令对比  

  |  git restore                                 |   git reset/checkout   |
  | :------------------------------------------: | :--------------------------------------------------------------------------------------------: |
  | commit方式                                   |                        |
  | git restore —source <commit id> <path/file>  | git reset <commit id> <path/file> / git checkout <commit id> <path/file> |
  | branch 方式                                  |                        |
  | git restore —source <branch/branch~num> <path/file> | git reset <branch/branch~num> <path/file> / git checkout <branch/branch~num> <path/file> |
  | tag 方式                                     |                        |
  | git restore —source <tag> <path/file>        | git reset <tag> <path/file> / git checkout <tag> <path/file> |


## patch

提供命令行交互恢复操作，对于路径或者一次要恢复很多文件的时候，可以通过`—patch`参数，筛选要恢复的文件

```bash
git restore --source master~2 --patch .
diff --git b/index.css a/index.css
new file mode 100644
index 0000000..830576d
--- /dev/null
+++ a/index.css
@@ -0,0 +1,4 @@
+* {
+  margin: 0;
+  padding: 0;
+}
(1/1) Apply this hunk to worktree [y,n,q,a,d,e,?]? Y

diff --git b/index.html a/index.html
index 02929d0..fbb52cc 100644
--- b/index.html
+++ a/index.html
@@ -4,6 +4,5 @@
     <title>Git Switch Restore</title>
   </head>
   <body>
-    <div>Hello World</div>
   </body>
 </html>
(1/1) Apply this hunk to worktree [y,n,q,a,d,e,?]? n

diff --git b/index.js a/index.js
new file mode 100644
index 0000000..e69de29
(1/1) Apply addition to worktree [y,n,q,a,d,?]?
```

- 新旧命令对比  

  |  git restore                                                  |   git reset/checkout   |
  | :-----------------------------------------------------------: | :----------------------------------------------------------------------------------------------------------: |
  | git restore —source <tag/branch/commit_id> <path/file> —patch | git reset <tag/branch/commit_id> <path/file> —patch / git checkout <tag/branch/commit_id> <path/file> —patch |


### staged

`--staged`操作的是git中的`index`区域. **tips!**: git docs 中index的意思是我们常说的git暂存区的概念。

默认恢复参照源是当前分支的`HEAD`同样我们也可以指定其他参照源(—source)，将`index`区域恢复到参照源状态

未恢复的`index`区域

```bash
[~/Documents/project/git_switch_restore]  on git:develop ✗  a8aee0f "feat(index.html): add Hello World text"
15:22:07 › git status
On branch develop
Your branch is up to date with 'origin/develop'.

Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
	new file:   index.css
	new file:   index.js
```

执行恢复后`index`区域状态

```bash
[~/Documents/project/git_switch_restore]  on git:develop ✗  a8aee0f "feat(index.html): add Hello World text"
15:22:09 › git restore --staged .

[~/Documents/project/git_switch_restore]  on git:develop ✗  a8aee0f "feat(index.html): add Hello World text"
15:22:17 › git status
On branch develop
Your branch is up to date with 'origin/develop'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	index.css
	index.js

nothing added to commit but untracked files present (use "git add" to track)
```

执行`git restore —staged <path/file>`后，会将`index`区域的文件状态恢复到恢复源的状态。

- 新旧命令对比  

  |  git restore                    |   git reset/checkout  |
  | :-----------------------------: | :-------------------: |
  | git restore —staged <path/file> | git reset <path/file> |

### worktree

`-- worktree`操作的是git中的worktree(工作区，当前未进行`git add`操作的修改), `--worktree`的恢复源是git中的`index`区域。


- 新旧命令对比  

  |  git restore                      |   git reset/checkout  |
  | :-------------------------------: | :-------------------: |
  | git restore —worktree <path/file> | git reset <path/file> |


`--worktree` 通常会和 `--staged`连用，`git restore --staged --worktree <path/file>`来达到撤销当前修改的操作。

### git提供的 restore 参数别名

git 为 `-source`、`-staged`、`-worktree` 提供了别名，`--source` == `-s`，`--staged` == `-S`，`--worktree` == `-W` 

将当前分支恢复到`HEAD`状态，可执行`git restore -s@ -SW .`;

感谢大家阅读。

