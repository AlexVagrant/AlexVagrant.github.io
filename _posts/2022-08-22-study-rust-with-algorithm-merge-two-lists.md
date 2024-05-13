---
layout: post
title: 通过算法学习rust之合并两个排序的链表
date: 2022-08-23 00:00:10  
categories: rust algorithm linklist
tag: [linklist] 
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
- 所有权之Move
- ref 关键字

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

### as_mut()方法

这里的链表题目我们可以看到使用了大量的`as_mut()`方法，我就就此来讨论一下，为什么要使用`as_mut()`方法以及`as_mut()`是如何实现的。

题目中有两个入参`l1`和`l2`，解决方案中要修改`l1`和`l2`，修改`l1`和`l2`的目的是为了剔除已经使用过的链表中节点

`as_mut`方法返回`l1`和`l2` `Option`内部包含的数据的`可变引用`，`as_mut`的调用必须保证`Option`本身或者其引用是可变的, 我们通过保存变量并设置`mut`关键字的方式，让入参变成可变变量，这样就不需要修改入参的类型

我们可以分析题目中的使用场景，来解答为什么需要使用`as_mut()`。

```rust
let next = l1.as_mut().unwrap().next.take();
cur = l1;
```

我们需要将`l1`中`next`节点保存在`next`变量中，我们通过`Option`中的`take()`可以获取到`next`的值，同时我们也修改了`l1`变量，所以我们需要`l1`是可变变量。

```rust
let mut l1 = l1;
```
### Move

`Rust`中以下操作会发生资源的移动（Move）

- 赋值操作
- 通过值来传递函数的参数
- 函数返回数据

```rust
let next = l1.as_mut().unwrap().next.take();
```

上面代码进行了`赋值`操作，所有权发生了转移，在移动资源之后，原来的所有者不能再被使用，这可避免悬挂指针（dangling pointer）的产生。

如果我们不使用`as_mut()`，`Rust`编译器会报错。

```rust
let next = l1.unwrap().next.take();
// `l1` moved due to this method call
cur = l1; // value used here after move
```
由此可见`Option`中`as_mut()`的主要作用就是为了获取可变变量的引用，来避免资源移动后产生的垂悬引用的问题。

### as_mut 的实现

> 实现的结果 `&mut Option<T>` -> `Option<&mut T>`

```rust
#[inline]
#[rustc_const_stable(feature = "const_option_basics", since = "1.48.0")]
#[stable(feature = "rust1", since = "1.0.0")]
pub const fn as_mut(&mut self) -> Option<&mut T> {
  match *self {
    Some(ref mut x) => Some(x),
    None => None,
  }
}
```

上面代码的`match`匹配值的模式，是rust中的`match 解构`

`as_mut`的入参类型是`&mut self`，这也是上面我们说的调用必须保证`Option`本身或者其引用是可变的.

`match *self`我们获取到的是`&mut self`这个可变引用指向的值, 如果我们不使用`match *self`进行的匹配的话，我们需要这样做（两种方式是相同的）

```rust
pub const fn as_mut(&mut self) -> Option<&mut T> {
  match self {
    &Some(ref mut x) => Some(x),
    None => None,
  }
}
```
### ref mut x

当我们需要绑定的是被匹配对象的引用时，可以使用ref关键字。
```rust
// 赋值语句中左边的 `ref` 关键字等价于右边的 `&` 符号。
let ref ref_c1 = c;
let ref_c2 = &c;

// 如果一开始就不用引用，会怎样？ `reference` 是一个 `&` 类型，因为赋值语句
// 的右边已经是一个引用。但下面这个不是引用，因为右边不是。
let _not_a_reference = 3;

// Rust 对这种情况提供了 `ref`。它更改了赋值行为，从而可以对具体值创建引用。
// 下面这行将得到一个引用。
let ref _is_a_reference = 3;
```
因为我们最终的目的是要将`&mut Option<T>`变为`Option<&mut T>`，所以我们需要的是`match`匹配对象的可变引用。

在`Some(ref mut x) => Some(x)`中我们通过`ref mut`两个关键字来创建一个`match`匹配到的对象的可变引用，最终`Some(x)`的类型就是`Option<&mut T>`。

这里还需要注意的是我们通过`Some()`创建了一个新的`Option`

### 总结

上述的所有知识点都是通过学习分析`as_mut`方法扩展开来的，我们为什么要用`as_mut()`，因为如果不用`as_mut`的话在此题目中会产生`所有权`问题。产生Move的三个场景`赋值操作`、`通过值来传递函数的参数`、`函数返回数据`，由此我们可以了解到使用`as_mut`就是为了获取可变变量的引用，来避免资源移动后产生的垂悬引用的问题。

同时我们通过学习`as_mut`的实现，学习了`match 解构`、`ref`关键字，以及如何将`&mut Option<T>`转化为`Option<&mut T>`。

希望通过这些知识点的挖掘和学习，让我们对所有权系统知根知底，无畏所有权。

### 参考链接

- <a href="https://doc.rust-lang.org/std/option/enum.Option.html">Rust Option as_mut</a>

- <a href="https://doc.rust-lang.org/src/core/option.rs.html#648">Rust Option as_mut source</a>

- <a href="https://rustwiki.org/zh-CN/rust-by-example/flow_control/match/destructuring/destructure_pointers.html">Rust 解构指针和引用</a>

- <a href="https://zhuanlan.zhihu.com/p/131689364">Rust模式解构</a>

- <a href="https://rustwiki.org/zh-CN/rust-by-example/scope/borrow/ref.html">Rust ref模式</a>
