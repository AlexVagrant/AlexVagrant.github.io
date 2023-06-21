---
layout: post
title: Dijkstra最短路算法
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

### 堆优化版Dijkstra算法
```c++
#include <iostream>
#include <cstring>
#include <algorithm>
#include <queue>

using namespace std;

#define ll long long

#define Debug(x) cout << #x << ':' << x << endl

#define x first

#define y second

typedef pair<int, int> PII;

const int N = 1.5e5+10;

int h[N], e[N], w[N], ne[N], idx;
int dist[N];
bool st[N];

int n, m;

void add(int a, int b, int c)
{
  e[idx] = b, w[idx] = c, ne[idx] = h[a], h[a] = idx++;
}

void dijkstra()
{
  memset(dist, 0x3f, sizeof dist);
  priority_queue<PII, vector<PII>, greater<PII>> q;
  q.push({0, 1});
  dist[1] = 0;
  
  while (q.size())
  {
    auto t = q.top();
    q.pop();
    int ver = t.second, distance = t.first;
    if (st[ver]) continue;
    st[ver] = true;
    for (int i = h[ver]; i != -1; i = ne[i])
    {
        int j = e[i];
        
        if (dist[j] > distance + w[i])
        {
            
            dist[j] = distance + w[i];
            q.push({dist[j], j});
        }
    }
  }
  if (dist[n] == 0x3f3f3f3f) printf("-1\n");
  else printf("%d\n", dist[n]);
}

int main()
{
  scanf("%d%d", &n, &m);  
  memset(h, -1, sizeof h);
  for (int i = 0; i < m; i++)
  {
    int a, b, c;
    scanf("%d%d%d", &a, &b, &c);
    add(a, b, c);
  }
  dijkstra();
  return 0;
}
```

### bellman-ford 算法
```c++
// bellman-ford
#include <iostream>
#include <algorithm>
#include <cstring>

using namespace std;

const int INF = 0x3f3f3f3f;
const int N = 510, M = 10000+10;

struct Edge
{
  int a, b, w;
} edges[M];

int dist[N], backup[N];
bool st[N];

int n, m, k;

void bellman_ford()
{
  memset(dist, 0x3f, sizeof dist);  
  memset(backup, 0x3f, sizeof backup);  
  dist[1] = 0;
  for (int i = 1; i <= k; i++) {
    memcpy(backup, dist, sizeof dist);
    for (int j = 1; j <= m; j++)
    {
      int a = edges[j].a, b = edges[j].b, w = edges[j].w;
      if (dist[b] > backup[a] + w) {
        dist[b] = backup[a] + w;
      }
    }
  }
  if (dist[n] >= INF / 2) puts("impossible");
  else printf("%d\n", dist[n]);
}

int main()
{
  scanf("%d%d%d", &n, &m, &k);
  for (int i = 1; i <= m; i++)
  {
    int a, b, w;
    scanf("%d%d%d", &a, &b, &w);
    edges[i] = {a, b, w};
  }

  bellman_ford();
  return 0;
}

```
### 参考文献
[^1]: [acwing 最短路笔记（1）Dijkstra朴素版](https://www.acwing.com/blog/content/140/)


