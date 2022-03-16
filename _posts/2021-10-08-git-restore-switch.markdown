---
layout: post
title: Git restore 和 Git switch
date: 2021-10-08 14:44:34 GMT+0800
categories: git
tag: git restore switch
---

<image src="/assets/images/git_restore.png"/>
 
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

### 通过 git switch -c <new-branch> 进行分支创建

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

### 通过 git switch -C <branch> 分支创建或重置
 
场景：假设我们接到了一个新需求，从master分支上创建了一个`feat/xxx`分支进行开发，当我们开发到中途时，当前的新需求被砍掉了，换成了一个和当前需求毫无关系的新需求，我们想还是继续使用`feat/xxx`分支开发，并且摒弃以前的修改时，就可以使用分支重置功能。
同时我们可以使用它来进行分之创建。

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

### 通过 git switch --detach 进行分离头指针操作

`git switch`命令不能像`git checkout <commit>`这样直接进行分离头指针的操作，依赖于`--detach`参数，`--detach`可以指定具体的commit或者是分支名,如果是分支名则会切换到对应分支的HEAD上;

分离头指针，可以简单理解为不在分支上操作，而是基于某一次commit进行操作，如果在进行修改后不进行保存，修改记录将会丢失，git会回收本次操作。

分离头指针找回方法： 如果不小心退出了分离头指针，并且未正确保存记录可以通过`git reflog`命令，查看最近的操作记录，找到对应的commitid并切换回去继续操作

### git switch 默认行为创建分支并和远端同名分支关联(--guess)

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

[Merge branch 'nd/switch-and-restore']: https://github.com/git/git/commit/f496b064fc1135e0dded7f93d85d72eb0b302c22
[gitster]: https://github.com/gitster
[git switch]: https://git-scm.com/docs/git-switch
