---
layout: post
title: 通过算法学习rust之二维数组中查找
date: 2022-04-15 11:43
categories: algorithm
tags: [rust]
---


> [题目地址](https://leetcode-cn.com/problems/er-wei-shu-zu-zhong-de-cha-zhao-lcof/)


此处我们不讨论算法题的解法是不是最优的，我们只关心使用rust解决算法题时可以学到哪些rust语法，通过练习加深对于rust的理解。

```rust
impl Solution {
  pub fn find_number_in2_d_array(matrix: Vec<Vec<i32>>, target: i32) -> bool {
  }
}

```

### 单元测试

通常我在开始解决算法问题之前，会先写单元测试，一是为了测试算法是否可以正常运行，二是为了测试算法题目中为给出的边界条件，rust单元测试格式大概如下：

```rust
#[cfg(test)]
mod test {
  use super::*;

  #[test]
  fn test_target_5() {
    let matrix= vec![
      vec![1,   4,  7, 11, 15],
      vec![2,   5,  8, 12, 19],
      vec![3,   6,  9, 16, 22],
      vec![10, 13, 14, 17, 24],
      vec![18, 21, 23, 26, 30]
    ];

    let ans = Solution::find_number_in2_d_array(matrix, 5);
    assert_eq!(ans, true);
  }

}

```

当我们直接从leetcode粘贴过来的测试用例时需要一个一个的在开头添加`vec!`感觉这种写法比较麻烦就去知乎上提问了个问题：



[Rust 有没有创建多维数组优雅的方式？](https://www.zhihu.com/question/465345382)

[Spore](https://www.zhihu.com/people/spore-96-93](https://www.zhihu.com/people/spore-96-93)给我提供了两种方案 1、`ndarray`，2、`macro_rules!`, 个人对`宏`解决方案比较感兴趣，就此学习一下如何定义多维数组宏。

宏定义的规则如下 `(Pattern) **=>** { Exapnsion };`，`宏`中可以定义多个规则，`rust`会对规则进行从上而下的匹配，当完全匹配时，会执行对应的操作。

`($([$($inner:tt)*]),+ $(,)*)`,`($($inner:tt)*)`都是`rust宏`的匹配规则，不同规则之间用 `;` 进行区分。

`$($name:params)` 小括号中的内容就是rust匹配模式，当rust宏规则完全匹配时，会将匹配都得内容标记为`$name`

```rust
macro_rules! vecn! {
	($($t:tt)*) => {
	    vec![$($t)*]
	};
}
```

`tt` 类型可以被视为 Rust 宏的 Any。上述代码的含义是匹配0个或者多个任意类型，返回一个包含了匹配到的所有的内容的`vec` 。 `$(...)*`对它包含的所有`$name`都执行“一层”重复

我们就可以通过`vecn!` 进行数组的创建。

```rust
let arr = vecn![1,2,3,4];
println!("{:?}", arr); // [1,2,3,4]
let arr1 = vecn![[1],[2],[3]];
println!("{:?}", arr1); // [[1],[2],[3]]
```

如此方式创建的二维数组打印出来的结果似乎没有问题呢，其实不然，我们可以通过打印一下数组中的一个元素类型来对比它和`vec` 的实质区别

```rust
use std::any::type_name;

fn print_type<T>(_: T) {
    println!("{:?}", { type_name::<T>() });
}
let v3 = vecn![
    [1],[2]
];
let v = vec![1];
test_type(v3[0]); // "[i32; 1]"
test_type(v); // "alloc::vec::Vec<i32>"
```

可以看出`"[i32; 1]"` 并不是一个`Vec` ，我们无法通过`"[i32; 1]"` 进行遍历，或者调用数组的方法。

我们需要匹配`[...]` 模式来进行处理，

```rust
macro_rules! vecnd! {
	($([$($inner:tt)*]),* $(,)*) => {
		vec![
			$(
				vec![$($inner)*]
			),*
		]
	}
}
let v3 = vecnd![
    [1,2,3],
    [4,5,6],
    [7,8,9],
];
```

`($([$($inner:tt)*]),* $(,)*)` 表示重复匹配`[pattern],` ，其中有个概念叫尾部分割符详情可以查看[宏小册](https://zjp-cn.github.io/tlborm/)

我们将匹配到的`$inner`用来创建第二维数组`vec![$($inner)*]` 然后进行重复创建`$(vec![$($inner)*]),*`

[Spore](https://www.zhihu.com/people/spore-96-93) 提到的递归宏更加有趣，匹配到`[pattern],` 不直接进行数组创建`$(vec![$($inner)*]),*`，而是再次调用`vecnd!` 直到匹配到不是`[pattern],` 模式后再进行数组创建，实现任意维度的数组，不过这种类型的数组在算法中并不常见。

```rust
macro_rules! vecnd {
	($([$($inner:tt)*]),* $(,)?) => {
		vec![$(
			// vec![$($inner)*] old
			vecnd![$($inner)*] // new
		),*]
	};

	// 匹配非 [pattern], 模式
	($($t:tt)*) => {
    vec![$($t)*]
  };

}

let v3 = vecnd![
    [[1, 2], [3, 4, 5]],
    [[6], [7, 8]],
];
```

最终我们使用`rust 宏` 创建的二维数组进行单元测试如下：

```rust
#[cfg(test)]
mod test {
  use super::*;

  #[test]
  fn test_target_5() {
    let matrix= vec![
      [1,   4,  7, 11, 15],
      [2,   5,  8, 12, 19],
      [3,   6,  9, 16, 22],
      [10, 13, 14, 17, 24],
      [18, 21, 23, 26, 30]
    ];

    let ans = Solution::find_number_in2_d_array(matrix, 5);
    assert_eq!(ans, true);
  }

}
```

### len方法返回值类型

```rust
impl Solution {
  pub fn find_number_in2_d_array(matrix: Vec<Vec<i32>>, target: i32) -> bool {
    if matrix.len() == 0 || matrix[0].len() == 0 {
      return false;
    }
    let (m, n) = (matrix.len(), matrix[0].len());
    let (mut column, mut row) = (n - 1, 0);
    while row < m && column >= 0 {
      let current = matrix[row][column];
      if current == target {
        return true;
      }
      if target > current {
        row += 1;
      } else {
        if column == 0 {
          return false;
        }
        column -= 1;
      }
    }
    false
  }
}
```

我们从上述代码中可以看到这样一行判断`if column == 0 { return false; }` 按照代码逻辑来看 `while` 已经做了 `column` 变量的边界条件判断，为什么还需要再加一行判断呢，我在写此题没加`column == 0` 的判断，提交时会有`thread 'main' panicked at 'attempt to subtract with overflow'` 减法导致栈溢出的问题。例如如下测试用例：

```rust
let matrix= vecnd![
	[0,3]
];

let target = -1;

let ans = Solution::find_number_in2_d_array(matrix, -1);
```

`column -= 1;` 会导致栈溢出这个让我困惑不解，知道我搜索过后了解到，`len()` 返回的数字类型是`usize` , `usize` 的范围在32位平台下[0, 2^32]，在64位平台下[0, 2^64]，看到`usize` 最小范围是0，当我们执行程序到 `0-1` rust就会报栈溢出的错误。

所以为了防止无符号整形的溢出，必然需要在减法之前编译进去一个范围判断。

以上就是通过二维数组查找所学到的知识点，作为个人学习记录，同时也希望能帮助到大家。
