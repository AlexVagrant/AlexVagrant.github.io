---
layout: post
title: "邻接表的理解、实现、遍历"
date: 2024-01-10
category: algorithm 
tags: 
---

邻接表数据结构一般是用来存图结构的，因为树是一种特殊的图，也可以使用邻接表来存树结构 

下面使用数组实现的邻接表是使用头插法存储节点的。

```c++
#include <iostream>
#include <algorithm>

using namespace std;

const int N = 10;

/**
* head 表示头节点的下标
* e[i] 表示节点i的值
* ne[i] 表示节点i的next指针是多好
* idx 存储当前最新已经用到了哪一个点了
*/
int h[N], e[N], ne[N], idx;
int n;

void add(int a, int b)
{
  e[idx] = b, ne[idx] = h[a], h[a] = idx++;
}

void dfs(int u)
{
  for (int i = h[u]; ~i; i = ne[i])
  {
    printf("%d\n", e[i]);
    dfs(e[i]);
  }
}

int main()
{
  scanf("%d", &n);

  memset(h, -1, sizeof h);

  while(n--)
  {
    int a, b;
    scanf("%d%d", &a, &b);
    // 这里如果要明确区分左右子树的话需要注意一下输入的顺序
    add(a, b);
  }

  dfs(1); 
  return 0;
}
```

输入值 

```
6
1 3
1 2
3 7
3 6
2 5
2 4
```


