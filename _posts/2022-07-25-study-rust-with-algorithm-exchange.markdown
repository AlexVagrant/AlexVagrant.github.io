---
layout: post
title: 通过算法学习rust之调整数组顺序使奇数位于偶数前面
tag: rust 
date: 2022-07-25 23:21
categories: rust algorithm
tag: rust algorithm vec ---

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

    if nums.len() == 0 {
      return nums;
    }

    let mut left = 0;
    let mut right = nums.len() - 1;
    
    while left < right {
      if nums[left] % 2 == 1 {
        left += 1;
        continue;
      }
      // 如果是偶数 并且 right是基数 就进行互换否则的话 right+1
      if nums[left] % 2 == 0 && nums[right] % 2 == 1 {
        let tmp = nums[left];
        nums[left] = nums[right];
        nums[right] = tmp;
      } else {
        right -= 1;
      } 
    } 
    nums
  }
}
```

### rust 所有权之二次释放问题

leetcode 给到的模版参数`nums`是一个不可变的`Vev<i32>`, 同时nums的所有权移动到了`exchange`函数中。

因为是不可变的参数，所以上述代码中`nums[left] = nums[right];`和`nums[right] = tmp;`执行会报错, 错误如下：

```
error[E0596]: cannot borrow `nums` as mutable, as it is not declared as mutable
--> src/main.rs:12:9
   |
1  | fn exchange(nums: Vec<i32>) -> Vec<i32> {
   |             ---- help: consider changing this to be mutable: `mut nums`
...
12 |         nums[left] = nums[right];
   |         ^^^^ cannot borrow as mutable
```

大体意思是不能将`nums`作为可变参数来借用，可以考虑修改`nums`为`mut nums`, 编译器提供的方案是完全可行的，那有没有什么其他方案在不改变传参行为的情况下通过编译器的检查的检查呢?

```rust
impl Solution {
  pub fn exchange(nums: Vec<i32>) -> Vec<i32> {
    let mut arr = nums;
    ...
  }
}
```

通过将参数重新赋值给函数体内可变变量来实现参数内容可变性。这种赋值方式并不是其他语言中的`浅拷贝`，因为在rust中`浅拷贝`会有二次释放的问题。在 Rust 中，在将一个`所有数据在堆上的变量`赋值给一个新变量时，`原来的变量会变成无效`，这个操作被称为 `移动`（move），这样就避免了二次释放问题。更多内容可以参考下面链接进行学习。

> [Rust程序设计语言-什么是所有权](https://kaisery.github.io/trpl-zh-cn/ch04-01-what-is-ownership.html)

### 位运算

我们判断奇偶数出了用`num % 2 == 0`来判断之外，还可以通过`位运算`来进行判断。

`位运算`中`&(与)`操作，会对二进制中的每一位进行`&(与)`操作, 如果两位都为1则为`1`，其他都为`0`。

`位运算`中基数最后一位都是`1`，所以我们可以通过`num & 1 == 1`来判断`num`是不是奇数，`num & 1 == 0` 判断`num`是不是偶数。

就此可以对上面代码进行如下修改(位运算相对取模运算性能更高)：

```rust
impl Solution {

  pub fn exchange(nums: Vec<i32>) -> Vec<i32> {
    ...
    while left < right {
      if nums[left] & 1 == 1 {
        ...
      }
      if nums[left] & 1 == 0 && nums[right] & 1 == 1 {
        ...
      } else {
        ...
      } 
    } 
    nums
  }
}
```

### swap方法

当左边指针指向的是偶数，右边指针指向的是奇数时，需要两个数据调换位置。这时需要设置一个中间变量`tmp`进行位置会还操作
```rust
impl Solution {

  pub fn exchange(nums: Vec<i32>) -> Vec<i32> {
    ...
    while left < right {
      if nums[left] & 1 == 1 {
        ...
      }
      if nums[left] & 1 == 0 && nums[right] & 1 == 1 {
        let tmp = nums[left];
        nums[left] = nums[right];
        nums[right] = tmp;
      } else {
        ...
      } 
    } 
    nums
  }
}
```

rust `Vec`提供了`swap`方法，可以轻松的完成此项操作。

```rust
impl Solution {

  pub fn exchange(nums: Vec<i32>) -> Vec<i32> {
    ...
    while left < right {
      if nums[left] & 1 == 1 {
        ...
      }
      if nums[left] & 1 == 0 && nums[right] & 1 == 1 {
        nums.swap(left,right);
      } else {
        ...
      } 
    } 
    nums
  }
}
```

### 总结

通过`调整数组顺序使奇数位于偶数前面`的学习中加深了对rust`所有权二次释放问题`，`move`等知识点的认知，希望也能帮助到看到这篇博客的人。
