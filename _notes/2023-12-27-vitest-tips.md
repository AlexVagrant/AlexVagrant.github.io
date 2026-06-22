---
layout: post
title: "vitest 测试技巧"
date: 2023-12-27
category: vitest
tags: [] 
---

## 如何使用单元测试的思维编写单元测试
> 单元测试，函数内部行为测试的宗旨，只关心函数产生的副作用是否有正确，不需要去关心函数内部其他函数调用是否正确
> 其他函数的调用测试应该由单独的测试覆盖 

## mount与shallowMount的区别 

> shallowMount behaves exactly like mount, but it stubs(存根) all child components by default. Essentially, shallowMount(Component) is an alias of mount(Component, { shallow: true }).

### vitest test console.error

```ts
it('should log an error', () => {
  vi.spyOn(console, 'error').mockImplementation(() => {})
  // do your logic
  expect(console.error).toHaveBeenCalledWith('your error message')
})
```

### vitest promise reject error

```ts
it("test promise reject error", async () => {
    await expect(request("https://example.com/api", {}, successEc, isToast, timeout)).rejects.toThrowError(
        "mk.ajax error~! {\"url\":\"https://example.com/api\",\"params\":{}}"
    );
})
```

### vitest test a class instance method call inside a function 

```ts
it("vitest test a class instance method call inside a function", async () => {
    vi.spyOn(IM.prototype, 'init').mockImplementation(() => {})
    const { dispatch } = useIMStore()
    await dispatch() // dispatch will call IM class init  
    expect(IM.prototype.init).toHaveBeenCalled() 
})
```

### vitest test vue3 plugin with arguments

```ts
it("vitest test vue3 plugin with arguments", async () => {
    //...
    const wrapper = shadowMount(ExampleComponent, {
        global: {
            plugins: [[MyPlugin, ...arguments]]
        }
    })
    //...
})
```

### testing hooks value change and method call in vue3 component

rootStore.ts
```ts
export let activeSome: undefined | any;

interface _SetActiveSome {
  (pinia: any): any
  (pinia: undefined): undefined
  (pinia: any | undefined): any | undefined
}

export const setActiveSome: _SetActiveSome = some => (activeSome = some)
```

index.ts (plugin & hook)
```ts
const somePlugin = {
  install(app: App) {
    const hooks = useSome()
    app.provide(SomeSymbol, hooks)
    app.config.globalProperties.$some = hooks
    if (!activeSome)
      setActiveSome(hooks)
  },
}

export function useSome() {
  return activeSome!
}

export {
    somePlugin,
    useSome,
}
```
