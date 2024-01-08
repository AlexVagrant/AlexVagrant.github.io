---
layout: post
title: "the shortest hamilton path"
date: 2024-01-09
category: algorithm
tags: 
---

> https://www.acwing.com/problem/content/93/

memset 函数是以字节为单位赋值的，int型变量所占的位数为4个字节，即32位

0x3f显然不是int型变量中单个字节的最大值，应该是0x7f=0111 1111 B

### 那为什么要赋值 0x3f?

1. 作为无穷大使用
因为 4 个字节均为 0x3f时，0x3f3f3f3f的十进制是1061109567，也就是10^ 9级别的（和0x7fffffff一个数量级）而一般场合下的数据都是小于10^9的，所以它可以作为无穷大使用而不致出现数据大于无穷大的情形

2. 可以保证无穷大加无穷大仍然不会超限。
另一方面，由于一般的数据都不会大于10^9，所以当我们把无穷大加上一个数据时，它并不会溢出（这就满足了“无穷大加一个有穷的数依然是无穷大”），事实上0x3f3f3f3f+0x3f3f3f3f=2122219134，这非常大但却没有超过32-bit int的表示范围，所以0x3f3f3f3f还满足了我们“无穷大加无穷大还是无穷大”的需求。

```c++
#include <iostream>
#include <cstring>
#include <algorithm>
#include <cmath>

using namespace std;

const int N = 20, M = 1 << N;

int f[M][N], w[N][N], n;


int main() {
    scanf("%d", &n);
    for (int i = 0; i < n; i ++ )
        for (int j = 0; j < n; j ++ )
            scanf("%d", &w[i][j]);
    
    memset(f, 0x3f, sizeof f); // 设置最大值，因为要求的是最小值
    f[1][0] = 0;
    for (int i = 0; i < M; i ++)
        for (int j = 0; j < n; j ++)
            if (i >> j & 1) // 可以从 i 到 j
                for (int k = 0; k < n; k ++)
                    if (i >> k & 1) // 可以从 i 到 j
                        // f[i - (1<<j)][k] 代表 i 没有经过 j 且当前到达了 k 的所有的路径
                        f[i][j] = min(f[i][j], f[i - (1 << j)][k] + w[k][j]);

    printf("%d\n", f[(1 << n) - 1][n - 1]);
    return 0;
}
```