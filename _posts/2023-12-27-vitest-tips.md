---
layout: post
title: "vitest 测试技巧"
date: 2023-12-27
category: vitest
tags: 
---

> 单元测试，函数内部行为测试的宗旨，只关心函数产生的副作用是否有正确，不需要去关心函数内部其他函数调用是否正确
> 其他函数的调用测试应该由单独的测试覆盖 

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


