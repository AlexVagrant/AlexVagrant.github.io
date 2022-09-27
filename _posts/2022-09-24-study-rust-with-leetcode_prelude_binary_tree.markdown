---
layout: post
title: 通过leetcode_prelude学习Rust之二叉树生成
date: 2022-08-24 22:30:00  
categories: rust algorithm binary_tree
tag: [rust, algorithm, binary_tree,] 
---

> [项目地址](https://github.com/Aloxaf/leetcode_prelude/blob/master/leetcode_prelude/src/btree.rs)

```rust
use std::cell::RefCell;
use std::rc::Rc;

/// Definition for a binary tree node.
///
/// # Note
///
/// I add Ord PartialOrd for sort Vec<TreeNode> when testing
/// Please don't rely on it
#[derive(Debug, PartialEq, Eq, Ord, PartialOrd)]
pub struct TreeNode {
    pub val: i32,
    pub left: Option<Rc<RefCell<TreeNode>>>,
    pub right: Option<Rc<RefCell<TreeNode>>>,
}

impl TreeNode {
    #[inline]
    pub fn new(val: i32) -> Self {
        TreeNode {
            val,
            left: None,
            right: None,
        }
    }
}

/// Create a binary tree with TreeNode
///
/// # Example
///
/// ```rust
/// use leetcode_prelude::btree;
///
/// let tree = btree![1, 2, 3, null, null, 4, 5];
/// ```
#[macro_export]
macro_rules! btree {
    () => {
        None
    };
    ($($e:expr), *) => {
        {
            use std::rc::Rc;
            use std::cell::RefCell;

            let elems = vec![$(stringify!($e)), *];
            let elems = elems.iter().map(|n| n.parse::<i32>().ok()).collect::<Vec<_>>();
            let head = Some(Rc::new(RefCell::new($crate::TreeNode::new(elems[0].unwrap()))));
            let mut nodes = std::collections::VecDeque::new();
            nodes.push_back(head.as_ref().unwrap().clone());

            for i in elems[1..].chunks(2) {
                let node = nodes.pop_front().unwrap();
                if let Some(val) = i[0]{
                    node.borrow_mut().left = Some(Rc::new(RefCell::new($crate::TreeNode::new(val))));
                    nodes.push_back(node.borrow().left.as_ref().unwrap().clone());
                }
                if i.len() > 1 {
                    if let Some(val) = i[1] {
                        node.borrow_mut().right = Some(Rc::new(RefCell::new($crate::TreeNode::new(val))));
                        nodes.push_back(node.borrow().right.as_ref().unwrap().clone());
                    }
                }
            }
            head
        }
    };
}

#[cfg(test)]
mod tests {

    #[test]
    fn test() {
        let btree = btree![-1, 2, 3, null];
        println!("{:#?}", btree);
    }
}

```

### 知识点列举

- stringify
- parse
- chunks
- VecDeque
- leetcode 数组转为二叉树

### 需要额外说明的点 

leetcode中使用`Rc`和`RefCell`构建二叉树是一种非常麻烦的操作，尤其是在解题的时候。leetcode代码模版是由机器生成的，所以无法控制后面这篇文章给出了[leetcode生成的 Rust 代码和优雅的 Rust 代码对比](https://github.com/pretzelhammer/rust-blog/blob/master/posts/translations/zh-hans/learning-rust-in-2020.md)

`Rc(引用计数)`和`RefCell(内部可变性)`很有意思也非常重要，他们的存在让我们可以像使用`GC语言`那样操作数据，含有的概念也很多需要单独拿出来分享。

`leetcode_prelude`只使用了一小部分宏的功能来进行数据处理，所以本次的重点不是在于宏的使用上，不过也会简单的介绍一下宏在使用处的含义和展开后生成的数据。

### stringify!

`let btree = btree![-1, 2, 3, null];` leetcode 输入是一个含有`null`值的数组，`Rust`中并没有`null`的关键字，所以需要对`null`进行单独处理。

`$($e:expr), *`捕获`btree!`宏中的内容,每次捕获的内容赋值给`$e`，如上例`$e`分别为`-1`, `2`, `3` ,`null`, 
我们可以通过宏语法轻松创建一个捕获值的数组`let elems = vec![$($e), *];`

我们运行时`Rust`编译器产生如下错误：

```rust
error[E0425]: cannot find value `null` in this scope
```
`Rust`会认为`null`是一个数据名称，`leetcode_prelude`使用`stringify!`宏将输入转化为字符串避免了在获取时因输入不规范产生的错误`let elems = vec![$(stringify!($e)), *];`。

`stringify!`会将捕获到的所有内容转化为一个`&'static str`类型的字符串，`let elems = vec![$(stringify!($e)), *];` 展开后为 `let elems = vec!["1","2","3","null"];`，这样就能覆盖到所有输入在不产生语法错误的同时进行下一步处理。

### parse

`leetcode_prelude`通过`stringify!`将输入数据转化为一个`Vec<&'static str>`类型，但是我们在解题的过程中处理的都是`i32`类型，`leetcode_prelude`通过`parse`将`Vec<&'static str>`转化为`Vec<Option<i32>>`类型，同时处理了`null`的问题`elems.iter().map(|n| n.parse::<i32>().ok()).collect::<Vec<_>>()`

`parse`可以将字符串切片变为其他的数据类型

有两种使用方式：

1. 在变量声明的时候声明变量的类型：

```rust
let four:Result<u32, _> = "4".parse();
```

2. 使用`turbofish`语法

```rust
let four = "4".parse::<u32>();
```

`leetcode_prelude`中使用的是`turbofish`语法，两种语法主要看使用场景，实际上没有任何区别。

```rust
#[inline]
#[stable(feature = "rust1", since = "1.0.0")]
pub fn parse<F: FromStr>(&self) -> Result<F, F::Err> {
  FromStr::from_str(self)
}
```
`parse`返回的是`Result<F, F::Err>`类型，`leetcode_prelude`通过`ok()`转化为`Option`类型，`Result`也是表示值存不存在的一种枚举但是它需要解释值不存在的原因，在算法中我们不关心值不存在的原因，只关心值存不存在所以我们只用`Option`类型即可。

### chunks 

`chunks`是`Vec`struct中的方法，这个方法的实现还是比较简单的，通过传入的`chunk_size`参数，返回一个Chunk实例。

```rust
#[stable(feature = "rust1", since = "1.0.0")]
#[inline]
pub fn chunks(&self, chunk_size: usize) -> Chunks<'_, T> {
  assert_ne!(chunk_size, 0, "chunks cannot have a size of zero");
  Chunks::new(self, chunk_size)
}
```
`assert_ne!`断言两个表达式不想等，如果两个表达式想等程序会`panic`并且输出传入的第三个参数作为错误信息。

`Chunks` struct 带有两个字段一个是类型为`&'a [T]`（[T] 静态数组）的v，一个是类型为`usize`的chunk_size

`Chunks` 实现了 `Iterator` `trait` 其中`next`方法值得分析一下

```rust
#[derive(Debug)]
#[stable(feature = "rust1", since = "1.0.0")]
#[must_use = "iterators are lazy and do nothing unless consumed"]
pub struct Chunks<'a, T: 'a> {
   v: &'a [T],
   chunk_size: usize,
}

impl<'a, T: 'a> Chunks<'a, T> {
  #[inline]
  pub(super) fn new(slice: &'a [T], size: usize) -> Self {
    Self { v: slice, chunk_size: size }
  }
}

#[stable(feature = "rust1", since = "1.0.0")]
impl<'a, T> Iterator for Chunks<'a, T> {
  type Item = &'a [T];

  #[inline]
  fn next(&mut self) -> Option<&'a [T]> {
    if self.v.is_empty() {
      None
    } else {
      let chunksz = cmp::min(self.v.len(), self.chunk_size);
      // fst 拆出来的，snd 剩下的
      let (fst, snd) = self.v.split_at(chunksz);
      self.v = snd;
      Some(fst)
    }
  }
  //...
}
 
```
`next`中会判断判断数组是否为空，会的话返回`None`，否则对数组的长度和`chunk_size`进行大小比较选择最小的那个作为拆分值，因为如果`split_at`的参数大于数组的长度的话程序会`painc`。`split_at`改变数组所以`next`中的入参是`&mut self`。

`split_at`会返回一个元组也就是按`chunksz`拆分后的内容，`fst`代表拆出来的数组，`snd`表示剩下的部分如下所示：

```rust
#![allow(unused)]
fn main() {
  let slice = ['l', 'o', 'r', 'e', 'm'];
  println!("{:?}", slice.split_at(2)); // (['l', 'o'], ['r', 'e', 'm'])
}
```

最后替换`Chunks`实例中`v`的内容，返回拆分出来的数组。

`leetcode_prelude`在for循环中使用了`chunks` => `for i in elems[1..].chunks(2)`

### VecDeque

`VecDeque`是`Rust`标准库中对于双端队列的实现。双端队列在`Rust`中相对于数组最大的优势是可以在数据结构的两端进行操作，数组只能对`push`进入的最新的数据进行操作。`VecDeque`有如下四个方法方便开发者操作：

- `pop_front`从第一个移除

- `pop_back`从最后一个移除

- `push_front`在最前面添加

- `push_back`添加到最后一个

需要注意的一点是`pop_*`有返回值类型是`Option<T>`，`push_*`没有返回值

### leetcode_prelude实现数组转化为二叉树步骤

```rust
let mut nodes = std::collections::VecDeque::new();
nodes.push_back(head.as_ref().unwrap().clone());
for i in elems[1..].chunks(2) {
  let node = nodes.pop_front().unwrap();
  if let Some(val) = i[0]{
    node.borrow_mut().left = Some(Rc::new(RefCell::new($crate::TreeNode::new(val))));
    nodes.push_back(node.borrow().left.as_ref().unwrap().clone());
  }
  if i.len() > 1 {
    if let Some(val) = i[1] {
      node.borrow_mut().right = Some(Rc::new(RefCell::new($crate::TreeNode::new(val))));
      nodes.push_back(node.borrow().right.as_ref().unwrap().clone());
    }
  }
}
```

1. 定义一个双端队列`nodes`，`nodes`添加数据都是从数据末尾添加。

2. 每次通过`chunks`方法取出两个数据，作为当前要操作的节点的左右子节点。

3. 当前要操作的节点通过双端队列的`pop_front`获取，这里主要是因为后面添加节点的顺序是先添加左节点，然后再添加右节点

4. 判断左右节点数据是不是存在，只要是为了处理`null`。如果存更新当前节点的左右子节点，并更新队列中的值。

下图是一个简单的数组转化为二叉树的过程供大家参考：

<img src="/assets/images/array_to_binary_tree.png" alt="">


### 总结

我们通过学习`leetcode_prelude`中通过`leetcode`给予的数组生成二叉树方法，学习了`stringify!`、`parse`、`chunks`、`VecDeque`的使用场景和部分原理。

`stringify!`将参数全部转化为`&'static str`字符串、`parse`转化字符串为指定的数据类型、`chunks`按照参数数字进行数组拆分、`VecDeque`双端队列可以进行队列的两端操作，尾部添加头部移除。

这个知识点不光在算法题中可以使用，在平常的项目开发中使用频率更高，希望这篇文章能帮助你理解`leetcode`二叉树的生成原理，`Rust`标准库中方法的使用场景以及如何使用，并且可以自主的通过官方文档学习`Rust`这些零成本抽象方法达到知其然知其所以然。


