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

### vitest promise reject error

```ts
test("test promise reject error", async () => {
    await expect(request("https://example.com/api", {}, successEc, isToast, timeout)).rejects.toThrowError(
        "mk.ajax error~! {\"url\":\"https://example.com/api\",\"params\":{}}"
    );
})
```
