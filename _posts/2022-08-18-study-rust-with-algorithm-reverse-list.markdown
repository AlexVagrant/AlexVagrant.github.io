---
layout: post
title: 通过算法学习rust之反转链表
tag: rust 
date: 2022-08-18 23:09
categories: rust algorithm linklist
tag: rust algorithm link list
---

> [题目地址](https://leetcode.cn/problems/fan-zhuan-lian-biao-lcof/)

```rust
// Definition for singly-linked list.
// #[derive(PartialEq, Eq, Clone, Debug)]
// pub struct ListNode {
//   pub val: i32,
//   pub next: Option<Box<ListNode>>
// }
// 
// impl ListNode {
//   #[inline]
//   fn new(val: i32) -> Self {
//     ListNode {
//       next: None,
//       val
//     }
//   }
// }
impl Solution {
    pub fn reverse_list(head: Option<Box<ListNode>>) -> Option<Box<ListNode>> {
    }
}
```

### 知识点列举

- take()方法
- mem::replace()方法

### 解题思路

```rust
impl Solution {
    pub fn reverse_list(head: Option<Box<ListNode>>) -> Option<Box<ListNode>> {
        let mut res: Option<Box<ListNode>> = None;
        let mut current = head;
        // 保存当前节点为tmp
        while let Some(mut tmp) = current.take() {
            // current就是当前节点的下一个节点
            current = tmp.next.take();
            // 因为上面已经将当前节点的下一个节点保存在current变量中，所有当前的节点可以换成上一个结果节点
            tmp.next = res.take();
            // 结果节点更新为最新的节点
            res = Some(tmp);
        }
        res
    }
}
```

### take()方法

`take()`方法将原值从`Option`中移除，保留`None`。我们在上面的题解中可以看到多处使用`take()`方法，我们来看一下`tmp`变量是如何从`current`链表获取值的。

```rust
while let Some(mut tmp) = current.take() {
  //...
}
```
此处将`tmp`设置为可变变量是因为下面有对`tmp`的修改。`tmp`的类型是`Box<ListNode>`。


### mem::replace()方法

通过查看`Option`中`take`方法可以看到，它其实使用`mem::replace()`实现替换值

```rust
#[inline]
#[stable(feature = "rust1", since = "1.0.0")]
#[rustc_const_unstable(feature = "const_option", issue = "67441")]
pub const fn take(&mut self) -> Option<T> {
    // FIXME replace `mem::replace` by `mem::take` when the latter is const ready
    mem::replace(self, None)
}
```

`mem::replace`是将`src`移到被引用的`dest`中, 并返回之前的`dest`的值。这两个值都不会被丢弃。

> pub fn replace<T>(dest: &mut T, src: T) -> T

```rust
use std::mem;
let mut v: Vec<i32> = vec![1,2];
let old_v = mem::replace(&mut v, vec![3,4,5]);
assert_eq!(vec![1, 2], old_v);
assert_eq!(vec![3, 4, 5], v);
```

所以上面`take`的`self`设置为`&mut`就是为了符合`mem::replace`中`src`的参数类型

`mem::replace`是通过`ptr::read`和`ptr::write`看到这里因为涉及到了内存管理，没怎么看明白，感兴趣的同学可以按照这个思路继续深入了`Rust`这些方法的具体实现，深入理解可以让我们运用自如。

### 参考链接


- <a href="https://doc.rust-lang.org/std/option/enum.Option.html#method.take">Rust Option take</a>

- <a href="https://doc.rust-lang.org/std/mem/fn.replace.html"> Rust mem::replace</a>
