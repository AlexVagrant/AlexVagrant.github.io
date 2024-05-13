---
layout: post
title: html2canvas不支持css省略号解决
date: 2023-10-20 13:15:32   
categories: js css
tag: [html2canvas] 
---

### html2canvas 目前只支持下面这些 css 属性

[https://github.com/niklasvh/html2canvas/blob/master/docs/features.md](https://github.com/niklasvh/html2canvas/blob/master/docs/features.md)

### 使用 js 来模拟 css 省略号

```vue
<template>
  <div class="report_wrapper">
    <!-- 请忽略反斜线， jekyll 模板语法不支持大括号文本-->
    <div ref="name" class="name">\{\{ starinfo.name \}\}</div>
    <!-- ... -->
  </div>
</template>
<script lang="ts">
  import { Component, Vue } from "vue-property-decorator";

  import html2canvas from "html2canvas";

  @Component({
    components: {},
  })
  export default class Report extends Vue {

    mounted() {
      this.$nextTick(() => {
        this.overflowhidden();
      })
    }

    overflowhidden() {
      const text = this.$refs.name;
      /**
      * lineHeight 获取元素的行高
      * maxHeight 计算元素的最大高度, 如果当前元素的最大高度超过 maxHeight 说明换行了
      */
      const compStyles = getComputedStyle(text, 'line-height'); 
      const lineHeight = compStyles.getPropertyValue('line-height').split('px')[0];
      const maxHeight = 1 * Math.ceil(+lineHeight);

      let tempstr = this.starinfo.name;
      let len = tempstr.length;
      // 记录当前遍历到了第几个字符
      let i = 0;
      /**
      * 如果文本的高度大于设定的最大高度对文本进行处理
      * 从 0 个字符开始遍历并判断，直到大于设定的最大高度后停止
      */
      if(text.offsetHeight > maxHeight) {
        var temp = "";
        text.textContent = temp;
       
        while(text.offsetHeight <= maxHeight){ // while 循环停止条件
            temp = tempstr.substring(0, i+1);
            i++;
            text.textContent = temp;
        }
        
        var slen = temp.length;
        /** 
        * 当判断条件停止时，当前文本的高度已经大于设定的最大高度
        * 这里需要删减一个字符已让文本高度达到预定值
        */
        tempstr = temp.substring(0, slen-1);
        len = tempstr.length
        // 最后删减 3 个字符并添加上省略号
        text.textContent = tempstr.substring(0, len-3) +"...";
        text.height = maxHeight +"px";
      }
    }

  }
</script>
<style lang="scss" scoped>

</style>
```
