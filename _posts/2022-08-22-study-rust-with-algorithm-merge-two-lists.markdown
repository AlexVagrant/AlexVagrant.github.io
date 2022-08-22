---
layout: post
title: 通过算法学习rust之合并两个排序的链表
tag: rust 
date: 2022-08-23 00:00:10  
categories: rust algorithm linklist
tag: rust algorithm link list
---

> [题目地址](https://leetcode.cn/problems/he-bing-liang-ge-pai-xu-de-lian-biao-lcof/)

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
    pub fn merge_two_lists(l1: Option<Box<ListNode>>, l2: Option<Box<ListNode>>) -> Option<Box<ListNode>> {
    }
}
```

### 知识点列举

- as_mut() 方法

### 解题思路

```rust
impl Solution {
    pub fn merge_two_lists(l1: Option<Box<ListNode>>, l2: Option<Box<ListNode>>) -> Option<Box<ListNode>> {
        let (mut l1, mut l2) = (l1, l2);

        if l1.is_none() {
            return l2;
        }
        if l2.is_none() {
            return l1;
        }
        let mut res: Option<Box<ListNode>> = Some(Box::new(ListNode{next: None, val: 0}));
        let mut ans = res.as_mut(); // 这个变量是为了保存当前链表最后一个元素
        while l1.is_some() && l2.is_some() {
            let mut cur: Option<Box<ListNode>> = None;
            if l1.as_ref().unwrap().val <= l2.as_ref().unwrap().val {
                let next = l1.as_mut().unwrap().next.take();
                cur = l1;
                l1 = next;
            } else {
                let next = l2.as_mut().unwrap().next.take();
                cur = l2;
                l2 = next;
            }
            
            ans.as_mut().unwrap().next = cur;
            ans = ans.unwrap().next.as_mut();
        }

        if l1.is_some() {
            ans.as_mut().unwrap().next = l1;
        } else {
            ans.as_mut().unwrap().next = l2;
        }
        res.unwrap().next
    }
}
```

