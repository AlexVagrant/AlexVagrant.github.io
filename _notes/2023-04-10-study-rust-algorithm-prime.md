---
layout: post
title: Rust之判断一个数字是否是质数/素数
date: 2023-04-10 21:37:06
categories: algorithm
tags: [prime, rust]
---

### 质数/素数定义：

> 一个大于1的自然数，除了1和它自身外，不能被其他自然数整除的数叫做质数

```rust
pub fn is_prime(n: usize) -> bool {
  let mut i = 2;
  while i * i <= n {
    if n % i == 0 {
      return false;
    }
    i++;
  }
  return n >= 2;
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn test_is_prime() {
        assert_eq!(is_prime(10),false);
        assert_eq!(is_prime(11),true);
    }
}

```
