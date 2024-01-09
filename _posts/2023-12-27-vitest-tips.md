---
layout: post
title: "vitest 测试技巧"
date: 2023-12-27
category: vitest
tags: 
---

### vitest test console.error

```ts
test('should log an error', () => {
  vi.spyOn(console, 'error').mockImplementation(() => {})
  // do your logic
  expect(console.error).toHaveBeenCalledWith('your error message')
})
```
