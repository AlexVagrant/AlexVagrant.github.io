---
layout: post
title: 最短路
date: 2023-06-07 15:49:00  
categories: c++ algorithm prime
tag: [shortest_path] 
---

### 最短路算法图谱 [^1]
<image src="/assets/images/shortest_path_0.png"/>

Dijkstra朴素算法与堆优化算法时间复杂度对比[^1]

|                         | 稠密图                            | 稀疏图                           |
|:----------------------- |:--------------------------------- |:-------------------------------- |
|                         | <font color="#ff0000">m≈n²</font> | <font color="#ff0000">m≈n</font> |
| 朴素Dijkstra (稠密图)   | n²                                | n²                               |
| 堆优化Dijkstra (稀疏图) | n² log n                          | m log n                          |

### 朴素Dijkstra算法

```c++
#include <iostream>
#include <cstring>

using namespace std;

const int N = 510; // Dijstra 关注的是点

int g[N][N];
int dist[N];
bool st[N];

int n, m;

void dijkstra()
{
  memset(dist, 0x3f, sizeof dist);

  dist[1] = 0;

  for (int i = 0; i < n - 1; i++)
  {

    int t = -1;

    for (int j = 1; j <= n; j++)
      if (!st[j] && (t == -1 || dist[t] > dist[j]))
        t = j;

    st[t] = true;
    for (int j = 1; j <= n; j++)
    {
      dist[j] = min(dist[j], dist[t] + g[t][j]);
    }
  }

  if (dist[n] >= 0x3f3f3f3f) puts("-1");
  else printf("%d\n", dist[n]);
}

int main()
{
    scanf("%d%d", &n ,&m);
    memset(g, 0x3f, sizeof g);
    for (int i = 0; i < m; i++)
    {
      int a, b, c; 
      scanf("%d%d%d", &a, &b, &c);
      g[a][b] = min(g[a][b], c);
    }
    dijkstra();
    return 0;
}
```

### 参考文献
[^1]: [acwing 最短路笔记（1）Dijkstra朴素版](https://www.acwing.com/blog/content/140/)


