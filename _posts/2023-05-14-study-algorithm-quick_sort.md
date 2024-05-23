---
layout: post
title: 双指针快速排序
date: 2023-05-14 23:16:32   
categories: algorithm
tag: [quick_sort, c++, prime] 
---

> https://www.acwing.com/problem/content/787/ 



```c++
#include <cstdio>
#include <algorithm>

using namespace std;

const int N = 1e6 + 10;
int n;
int q[N];

void quick_sort(int q[], int l, int r)
{
  if (l >= r) return;
  int x = q[(l+r) >> 1], i = l - 1, j = r + 1;
  while (i < j)
  {
    do i++; while(q[i] < x);
    do j--; while(q[j] > x);
    if (i < j) swap(q[i], q[j]);
  }
  quick_sort(q, l , j), quick_sort(q, j+1, r);
}

int main()
{
  scanf("%d", &n);
  for (int i = 0; i < n; i++) scanf("%d", &q[i]);
  quick_sort(q, 0, n-1);
  for (int i = 0; i < n; i++) printf("%d ", q[i]);
  return 0;
}
```

### do-while替换写法 do-while的写法更加直观一些
```
while (q[++i] < x);
while (q[--j] > x);
```
