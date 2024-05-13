---
layout: post
title: 通过算法学习rust之链表中倒数第K个节点
date: 2022-08-06 22:55
categories: rust algorithm
tag: [algorithm] 
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
### 知识点列举

- as_ref()方法
- is_some()方法 
- cloned()方法

### 解题思路

双指针通过设置两个指针的间距，和给定的k相同，当前面的指针到达底部时，后面的指针所拥有的节点就是题目中所要找到的节点

```rust
impl Solution {
  pub fn get_kth_from_end(head: Option<Box<ListNode>>, k: i32) -> Option<Box<ListNode>> {
    let mut start = head.as_ref();
    for i in 0..k {
      match start.take() {
        Some(node) => start = node.next.as_ref(),
        None => {
          return None;
        }
      }
    }
    let mut end = head.as_ref();
    while let Some(node) = start.take() {
      start = node.next.as_ref();
      end = end.unwrap().next.as_ref();
    }
    end.cloned()
  }
}
```

### as_ref() 是什么 为什么需要使用as_ref()

一开始`start`和`end`两个可变变量并没有使用`head.as_ref()`来设置变量指向的节点值，而是使用`clone()`方法。

`clone()`方法拷贝了两个相同的`head`链表，第一次提交时发现内存占比较高只超过16%的用户.

```
执行用时：0 ms, 在所有 Rust 提交中击败了100.00%的用户
内存消耗：2.2 MB, 在所有 Rust 提交中击败了16.67%的用户
```

通过查询题解发现，大部分人使用的是`as_ref()`方法,当我讲`clone()`替换为`as_ref()`时，数据如下所示，看起来还是非常可观的。

```
执行用时：0 ms, 在所有 Rust 提交中击败了100.00%的用户
内存消耗：1.9 MB, 在所有 Rust 提交中击败了93.33%的用户
```

`as_ref()`是转引用函数，将具有所有权对象转换成引用对象，在不改变被转换对象的基础上产生一个引用对象。
目前有：`Option`, `Box`，`Result`这三种类型默认提供支持as_ref

`Brrow`允许owner把自已的拥用权“借出”，borrow实际上创建了到原始资源的reference.


`Borrow`可以直接在`int`, `&str`, `String`, `vec`, `[]`, `struct`, `enum` 类型上直接指定&来引用。

`as_ref()`则不行，它需要声明泛型 `T：AsRef<int>`, `T: AsRef<str>`, `T:AsRef<struct name>` 来支持。

#### 实现`AsRef trait`<sup><a href="#ref1">1</a></sup>

由于`String`和`&str`都实现了`AsRef<str>`，所有我们可以接受`String`和`&str`作为参数,可以调用`as_ref()`方法转化为`&str`

```rust
fn is_hello<T: AsRef<str>>(s: T) {
  assert_eq!("hello", s.as_ref());
}

fn main() {
  // s1是&str类型, str类型实现了AsRef<str>，&str也实现了AsRef<str>
  let s1 = "hello";
  is_hello(s1);
  // s2是String类型, 实现了AsRef<str>, &String也实现了AsRef<str>
  let s2 = "hello".to_string();
  is_hello(s2);
}
```

上面`is_hello`方法的泛型定义是`trait bound`语法，因为例子场景比较直观，也可以使用`trait bound`的语法糖

```rust
fn is_hello(s: impl AsRef<str>) {
  assert_eq!("hello", s.as_ref());
}
```

为未实现的类型实现`AsRef<T>`，因为`AsRef<T>`是`trait`我们要实现其中定义的方法`AsRef<T>` trait 定义如下：

```rust
pub trait AsRef<T>
where
    T: ?Sized, 
{
    fn as_ref(&self) -> &T;
}
```

```rust
enum Msg {
  Hello,
  World,
}

impl AsRef<str> for Msg {
  fn as_ref(&self) -> &str {
    match self {
      Msg::Hello => "hello",
      Msg::World => "world",
    }
  }
}

fn main() {
  let msg = Msg::Hello;
  assert_eq!("hello", msg.as_ref());
}
```

### is_some() 是什么

如果想知道一个`Option`是否含有值，但不会使用到值的时候，可以用`is_some()`来进行判断`is_some()`
返回的是`Boolean`

```rust
let has_item = if let Some(_value) = option { true } else { false };
// becomes
let has_item = option.is_some();
```

下面这段描述了什么场景下可以使用`is_some()`以及如何使用，下面的使用场景比较单一因为场景只针对于本题不做额外的扩展

下面使用`is_some()`也不是最优场景，只是介绍这里可以使用`is_some()`；

```rust
impl Solution {
  pub fn get_kth_from_end(head: Option<Box<ListNode>>, k: i32) -> Option<Box<ListNode>> {
    ... 
    while let Some(node) = start.take() {
      ...
      // 修改前
      end = end.unwrap().next.as_ref();
      // 修改后
      if end.is_some() {
        end = end.next.as_ref(); 
      }
    }
    ...
  }
}
```

### cloned() 
```rust
pub fn cloned(self) -> Option<T>
where
    T: Clone, 
```

通过clone Option 中的内容将`Option<&T>`映射到`Option<T>`

```rust
let x = 12;
let opt_x = Some(&x);
assert_eq!(opt_x, Some(&12)); //ok
let cloned = opt_x.cloned();
assert_eq!(cloned, Some(12)); //ok
```

下面是`Rust`源码中`Option cloned`的实现，可以看到`cloned`内部是帮开发人员处理`Some`和`None`的情况，其中`Some`中调用了`clone()`方法

```rust
impl<T> Option<&mut T> {
  #[must_use = "`self` will be dropped if the result is not used"]
  #[stable(feature = "rust1", since = "1.0.0")]
  #[rustc_const_unstable(feature = "const_option_cloned", issue = "91582")]
  pub const fn cloned(self) -> Option<T>
  where
    T: ~const Clone,
  {
    match self {
      Some(t) => Some(t.clone()),
      None => None,
    }
  }
}
```
`clone()`方法是`Rust`内置trait`Clone`中的方法,`derive` 属性会在使用 `derive` 语法标记的类型上生成对应 `trait` 的默认实现的代码。在上面结构体中已经添加了`Clone`

```rust
#[derive(PartialEq, Eq, Clone, Debug)]
pub struct ListNode {
  pub val: i32,
  pub next: Option<Box<ListNode>>
}
```

`clone()`方法大概如下所示:

```rust 
pub struct ListNode {
  pub val: i32,
  pub next: Option<Box<ListNode>>
}
impl<T> Clone for ListNode {
  fn clone(&self) -> Self {
    *self 
  }
}

```

到此处我们应该可以理解`cloned()`到底做什么事情，怎么做的，在哪里用。探究的过程也让我加深了对`Rust`内置`trait`的理解，学会如何查询`Rust`内置`trait`的实现。

### 总结

`as_ref()`、`is_some()`、`cloned()` 属于基础方法，在`Rust`中使用频率非常高，希望这篇文章可以加深对`Rust`基础方法的理解，在世纪开发过程中能运用自如。


### 参考链接

1. <a name="ref1" href="https://blog.frognew.com/2020/07/rust-asref-and-asmut-trait.html">rust语言基础学习: 使用AsRef和AsMut trait实现不同引用之间的转换</a>

- <a href="https://doc.rust-lang.org/std/convert/trait.AsRef.html" target="_blank">https://doc.rust-lang.org/std/convert/trait.AsRef.html</a>

- <a href="https://doc.rust-lang.org/src/core/option.rs.html#1827-1829">Rust Option cloned</a>

- <a href="https://doc.rust-lang.org/std/clone/trait.Clone.html"> Rust trait.Clone</a>
