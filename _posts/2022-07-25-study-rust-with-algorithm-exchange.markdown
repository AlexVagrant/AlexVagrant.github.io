---
layout: post
title: 通过算法学习rust之调整数组顺序使奇数位于偶数前面
tag: rust 
date: 2022-07-25 23:21
categories: rust algorithm
tag: rust algorithm vec
---

> [题目地址](https://leetcode.cn/problems/diao-zheng-shu-zu-shun-xu-shi-qi-shu-wei-yu-ou-shu-qian-mian-lcof/)

```rust
impl Solution {
  pub fn exchange(nums: Vec<i32>) -> Vec<i32> {

  }
}
```

### 知识点列举

- rust所有权之二次释放问题
- 位运算
- swap 方法 

### 解题思路

此题目我是使用双指针解决的，前后两个指针，左边指针永远只能是奇数，右边指针只能是偶数，如果不是的话进行数据互换。

```rust
impl Solution {
  pub fn exchange(nums: Vec<i32>) -> Vec<i32> {
    let mut left = 0;
    let mut right = nums.len() - 1;
    while left < right {
      if arr[left] % 2 == 1 {
        left += 1;
        continue;
      }
      // 如果是偶数 并且 right是基数 就进行互换否则的话 right+1
      if arr[left] % 2 == 0 && arr[right] % 2 == 1 {
        let mut tmp = arr[left];
        arr[left] = arr[right];
        arr[right] = tmp;
      } else {
        right -= 1;
      } 
    } 
  }
}
```

### rust 所有权之二次释放问题
