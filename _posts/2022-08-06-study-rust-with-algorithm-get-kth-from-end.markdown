---
layout: post
title: 通过算法学习rust之链表中倒数第K个节点
tag: rust 
date: 2022-08-06 22:55
categories: rust algorithm
tag: rust algorithm vec ---
---

> [题目地址](https://leetcode.cn/problems/lian-biao-zhong-dao-shu-di-kge-jie-dian-lcof/)


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
    pub fn get_kth_from_end(head: Option<Box<ListNode>>, k: i32) -> Option<Box<ListNode>> {
        
    }
}
```
### as_ref 是什么
as_ref是转引用函数，将具有所有权对象转换成引用对象，在不改变被转换对象的基础上产生一个引用对象。


### is_some() 是什么
如果想知道一个`Option`是否含有值，但不会使用到值的时候，可以用`is_some()`来进行判断`is_some()`
返回的是`Boolean`
```rust
let has_item = if let Some(_value) = option { true } else { false };
// becomes
let has_item = option.is_some();
```
