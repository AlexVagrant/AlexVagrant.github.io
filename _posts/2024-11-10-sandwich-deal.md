---
layout: post
title: "三明治交易"
date: 2024-11-10
category: blockChain
tags: [ sandwichDeal ]
---

> 假设交易者A提交了一笔交易，用10个代币X兑换代币Y，滑动价差容差为1%（交易者A愿意接受最终获得的价值存在1%的差异），在持有100个代币X和100个代币Y的资金池中燃料费收取0.3%。
根据这些参数，交易者A预计将收到9.066个代币Y。

### 9.066个代币Y的计算逻辑


假设资金池中有 100 个代币 X 和 100 个代币 Y，交易者 A 要用 10 个代币 X 兑换代币 Y。

首先，我们先来看看常用的自动做市商（AMM）模型——恒定乘积模型，它的公式是：

$$
x \cdot y = k
$$

其中 \( x \) 和 \( y \) 分别是池中的代币数量，\( k \) 是一个恒定值。在交易之前：

$$
x = 100, \quad y = 100
$$

$$
k = x \cdot y = 100 \cdot 100 = 10000
$$

### 1. 计算燃料费
燃料费（交易费）为 0.3%，因此实际交易输入的代币 X 数量会减少：

$$
10 \times (1 - 0.003) = 10 \times 0.997 = 9.97
$$

也就是说，只有 9.97 个代币 X 实际用于兑换。

### 2. 计算兑换后池中的代币数量
因为 \( k \) 是恒定的，我们可以通过以下步骤求出交易后池中的代币 Y 数量 \( y' \)：

$$
(x + 9.97) \cdot y' = 10000
$$

将 \( x + 9.97 = 109.97 \) 带入：

$$
109.97 \cdot y' = 10000
$$

$$
y' = \frac{10000}{109.97} \approx 90.934
$$

### 3. 计算得到的代币 Y 数量
交易者 A 得到的代币 Y 数量为交易前的 Y 数量减去交易后的 Y 数量：

$$
100 - 90.934 = 9.066
$$

因此，交易者 A 最终会收到约 9.066 个代币 Y。


### 参考文章
- [三明治交易](https://academy.binance.com/zh/glossary/sandwich-trading)
- [DeFi科普系列之（一）：Uniswap到底是怎么运转的？](https://medium.com/cortexlabs/defi%E7%A7%91%E6%99%AE%E7%B3%BB%E5%88%97%E4%B9%8B-%E4%B8%80-uniswap%E5%88%B0%E5%BA%95%E6%98%AF%E6%80%8E%E4%B9%88%E8%BF%90%E8%BD%AC%E7%9A%84-2a82c9afc1df#id_token=eyJhbGciOiJSUzI1NiIsImtpZCI6IjFkYzBmMTcyZThkNmVmMzgyZDZkM2EyMzFmNmMxOTdkZDY4Y2U1ZWYiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiIyMTYyOTYwMzU4MzQtazFrNnFlMDYwczJ0cDJhMmphbTRsamRjbXMwMHN0dGcuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiIyMTYyOTYwMzU4MzQtazFrNnFlMDYwczJ0cDJhMmphbTRsamRjbXMwMHN0dGcuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDg1MTI2NDI2MTM2MjkzMDgwOTAiLCJlbWFpbCI6IndzZW1haWwxOTU3MkBnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwibmJmIjoxNzMxMjQ2MDI2LCJuYW1lIjoi546L54i9IiwicGljdHVyZSI6Imh0dHBzOi8vbGgzLmdvb2dsZXVzZXJjb250ZW50LmNvbS9hL0FDZzhvY0loWTBmRWR5b01KUHRpMHN0T0YyUnh6ZE04Unlib01LTUxkZ05fS1pfXzF2SWhMSnM9czk2LWMiLCJnaXZlbl9uYW1lIjoi54i9IiwiZmFtaWx5X25hbWUiOiLnjosiLCJpYXQiOjE3MzEyNDYzMjYsImV4cCI6MTczMTI0OTkyNiwianRpIjoiNzEyMDI3ZWY1NDBmMmJlZGE0MTljMWUzNjA2ZWVhOTAzNDE0NTdhZSJ9.yFW-LQvoh1WJ0GQUuKHMoec9pwDVhNr91c_ehS3ljHDtI2eOPxf7DfHca7cGvaWuLFERfYzu_aTz-Mudfm269p4S3K569j0eeGjhP6qX4aGiivvmZW1i0chcaw_ltOp5O2SC3mOx6em-Sw5Wl0LYKIG6QYzONUUyKQn0YuKrJnHJUCjj8XHyqj840R8UoQ4RPQhMvm4nzIYRncdZKmKQe4c0ZRGDJGpoXpnXBRoI9IZ_LyDLPE-4yqv7BazJYLaEImjbpKk24CG8pPCujXVVdYf_DFiYONMH7r5fojxVofqN4t4jS9tWzL4m6Kx_RAv4GwALpdqev8ndJWDmWfp3yg)