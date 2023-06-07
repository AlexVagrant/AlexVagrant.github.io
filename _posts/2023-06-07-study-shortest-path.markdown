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



### 参考文献
[^1]: [acwing 最短路笔记（1）Dijkstra朴素版](https://www.acwing.com/blog/content/140/)



