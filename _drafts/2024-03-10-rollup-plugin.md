---
layout: post
title: "rollup plugin"
date: 2024-03-10
category: rollup plugin 
tags: [rollup]
---

# rollup plugin example 

```js
// rollup-plugin-my-example.js
export default function myExample () {
  return {
    name: 'my-example', // this name will show up in logs and errors
    resolveId ( source ) {
      if (source === 'virtual-module') {
        // this signals that Rollup should not ask other plugins or check
        // the file system to find this id
        return source;
      }
      return null; // other ids should be handled as usually
    },
    load ( id ) {
      if (id === 'virtual-module') {
        // the source code for "virtual-module"
        return 'export default "This is virtual!"';
      }
      return null; // other ids should be handled as usually
    }
  };
}

// rollup.config.js
import myExample from './rollup-plugin-my-example.js';
export default ({
  input: 'virtual-module', // resolved by our plugin
  plugins: [myExample()],
  output: [{
    file: 'bundle.js',
    format: 'es'
  }]
});
```

# build hook

[![build hook](/assets/images/rollup-plugin-build-hook.png)](https://rollupjs.org/plugin-development/#build-hooks)

# output hook

[![output hook](/assets/images/rollup-output-hook.png)](https://rollupjs.org/plugin-development/#output-generation-hooks)


# 参考链接
- [深入理解 Rollup 的插件机制](https://segmentfault.com/a/1190000043830025#item-2-2)
