---
layout: post
title: Git restore 和 Git switch 基本API使用 一
date: 2021-10-08 14:44:34 GMT+0800
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


## git switch
----

<br/>

### 1、分支创建

**command:** `git switch -c <new-branch>`

场景： 在实际的开发过程中，我们要修改或者项目开始的时候都会创建一个自己的开发分支进行开发，避免污染已经上线的分支或者其他同事的分支。

- 基于当前分支创建, 创建分支时不指定基础分支名

  ```sh 
  git switch -c <new-branch>
  ```

- 基于远程或者本地的非当前分支进行创建

  ```sh
  git switch -c <new-branch> <remote/local-branch>
  ```
- 新旧命令对比  

  |  git switch   |   git checkout   |
  | :-----------: | :--------------: |
  | git switch -c | git checkout -b  |

### 2、分支创建或重置 

**command:** `git switch -C <new-branch>`

场景：假设我们接到了一个新需求，从master分支上创建了一个`feat/xxx`分支进行开发，当我们开发到中途时，当前的新需求被砍掉了，换成了一个和当前需求毫无关系的新需求，我们想还是继续使用`feat/xxx`分支开发，并且摒弃以前的修改时，就可以使用分支重置功能。
同时我们可以使用它来进行分支创建。

- 分支重置

我们可以使用如下命令进行分支重置，默认重置到命令执行所在分支，未提交到暂存区的修改也会被放到重置分支上

```sh
  git switch -C <branch>
```

同时我们也可以指定重置到具体的分支上

```sh
git switch -C <branch> <remote/local-branch>
```

- 分支创建

```sh
  git switch -C <new-branch>
```

- 新旧命令对比  

  |  git switch   |   git checkout   |
  | :-----------: | :--------------: |
  | git switch -c | git checkout -B  |


### 3、分离头指针

**command:** `git switch --detach`

`git switch`命令不能像`git checkout <commit>`这样直接进行分离头指针的操作，依赖于`--detach`参数，`--detach`可以指定具体的commit或者是分支名,如果是分支名则会切换到对应分支的HEAD上;

分离头指针，可以简单理解为不在分支上操作，而是基于某一次commit进行操作，如果在进行修改后不进行保存，修改记录将会丢失，git会回收本次操作。

分离头指针找回方法： 如果不小心退出了分离头指针，并且未正确保存记录可以通过`git reflog`命令，查看最近的操作记录，找到对应的commitid并切换回去继续操作

- 新旧命令对比  

  |  git switch            |   git checkout         |
  | :-----------:          | :--------------:       |
  | git switch -d <commit> | git checkout <commit>  |


### 4、创建分支并和远端同名分支关联

**command:** `git switch --guess <branch> or  git switch <branch>`

当我们通过`git fetch`同步远端仓库，然后从远端中的新分支进行开发，可以直接使用`git switch remote/branch`进行创建，这里命令行中会出现如下提示:

```
分支 'feat/guess_branch' 设置为跟踪来自 'origin' 的远程分支 'feat/guess_branch'。
切换到一个新分支 'feat/guess_branch'
```

 分析上面的信息看一下`git switch remote/branch`都做了什么操作
 - 分支 'feat/guess_branch' 设置为... -> 执行了创建操作
 - 设置为跟踪来自 'origin' 的远程分支 'feat/guess_branch' -> 为新分支设置上游信息操作
 - 切换到一个新分支 'feat/guess_branch' -> 切换分支操作
 
 可以理解为`git switch remote/branch` 是下面命令的一种简写模式
 ```
  $ git switch -c <branch> --track <remote>/<branch>
 ```
- 新旧命令对比  

  |  git switch         |   git checkout       |
  | :-----------:       | :--------------:     |
  | git switch branch   | git checkout branch  |

### 5、丢弃当前工作区修改并切换分支

**command**：`git switch -f <branch> or git switch <branch> -f`

<image src="/assets/images/working_tree&staging_area.png"/>
<br/>

执行此操作，会丢弃当前工作区的所有修改，并切换到指定的分支，如果分支不存在，会报错。

工作区的修改包含，已经添加到暂存区的修改（git add .），不包含已经提交到本地仓库的修改(git commit -m"")。

- 新旧命令对比  

  |  git switch            |   git checkout          |
  | :-----------:          | :--------------:        |
  | git switch -f branch   | git checkout -f branch  |

### 6、切换分支并执行三路合并操作

**command:** `git switch -m <branch>`

首先要明确一下三路合并中的三路分别是什么?

1. 本地修改的一个或者多个文件（local modification to one or more files)
2. 当前分支（current branch）
3. 你将要切换到的分支（branch to which you are switching）

现在让我们来创建这三路，然后再来看看`git switch -m`是怎样操作的

- 本地修改一个或者多个文件
<image src="/assets/images/git_three_way_merge_1.png"/>

- 你将要切换到的分支
<image src="/assets/images/git_three_way_merge_2.png"/>

- 当前分支
<image src="/assets/images/git_three_way_merge_3.png"/>

当我们执行 `git switch -m develop3` 时，会出现如下提示：

```sh
➜  git_switch_restore git:(develop4) ✗ git switch -m develop3
M       index.html
M       index.js
切换到分支 'develop3'
您的分支与上游分支 'origin/develop3' 一致。
➜  git_switch_restore git:(develop3) ✗ 
```

然后我们再使用 `git status` 查看three-way merge的状态，会看到如下结果：

```sh
➜  git_switch_restore git:(develop3) ✗ git status
位于分支 develop3
您的分支与上游分支 'origin/develop3' 一致。

未合并的路径：
  （使用 "git restore --staged <文件>..." 以取消暂存）
  （使用 "git add <文件>..." 标记解决方案）
        双方修改：   index.js

尚未暂存以备提交的变更：
  （使用 "git add <文件>..." 更新要提交的内容）
  （使用 "git restore <文件>..." 丢弃工作区的改动）
        修改：     index.html

修改尚未加入提交（使用 "git add" 和/或 "git commit -a"）
➜  git_switch_restore git:(develop3) ✗ 
```

其中产生了一个未合并的文件，这个文件是由于我们在`git switch -m`命令时产生的冲突文件，需要我们手动解决冲突，后面就是正常的merge后解决冲突、提交等操作了。

至此，`git switch -m` 命令所有的操作已经完成了，希望这里可以帮助大家很好的理解`git switch -m`命令到底做了什么。

三路合并（three-way merge）也是我第一次接触的概念，它是一种比较复杂的操作，在此不做过多的解释，只是说明一下，它是如何工作的。后面有机会再给大家解释一下三路合并的原理。

### git switch 小结

以上应该是`git switch`命令最常用的API，虽然还有很多API，但是我们这里不再赘述，因为当前API可以覆盖日常使用的90%需求了。
文章有任何疑惑、错误，希望大家可以通过github指正修改。

[Merge branch 'nd/switch-and-restore']: https://github.com/git/git/commit/f496b064fc1135e0dded7f93d85d72eb0b302c22
[gitster]: https://github.com/gitster
[git switch]: https://git-scm.com/docs/git-switch
