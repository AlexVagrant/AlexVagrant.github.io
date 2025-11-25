# GitHub Pages 缓存处理指南

## 问题说明

GitHub Pages 发布后更新不生效的原因通常是多层缓存：

1. **浏览器缓存** - 本地浏览器缓存了旧的静态资源
2. **CDN 缓存** - GitHub 的 CDN 缓存（10-15分钟）
3. **Jekyll 构建缓存** - 本地的 `.jekyll-cache` 缓存

## 解决方案

### 1. 自动方案（推荐）✨

已经为项目添加了自动缓存破坏机制：

- CSS 文件会自动添加时间戳参数（例如：`main.css?v=1234567890`）
- 每次 Jekyll 构建时都会生成新的时间戳
- 浏览器会将其视为新文件，自动获取最新版本

### 2. 手动清理本地缓存

使用提供的清理脚本：

```bash
./clear_cache.sh
```

或手动清理：

```bash
# 清理所有缓存
rm -rf _site .jekyll-cache .sass-cache .jekyll-metadata

# 重新构建
bundle exec jekyll serve
```

### 3. 清理浏览器缓存

#### 快捷键强制刷新
- **Mac**: `Cmd + Shift + R`
- **Windows/Linux**: `Ctrl + Shift + R` 或 `Ctrl + F5`

#### 开发者工具
1. 打开开发者工具（F12）
2. 右键点击刷新按钮
3. 选择"清空缓存并硬性重新加载"

#### 禁用缓存（开发时）
1. 打开开发者工具（F12）
2. Network 标签
3. 勾选 "Disable cache"

### 4. 等待 CDN 缓存过期

如果急需更新：
- GitHub CDN 缓存通常 10-15 分钟后过期
- 可以等待一段时间后再检查

### 5. 验证更新是否生效

```bash
# 使用 curl 检查文件内容（绕过浏览器缓存）
curl -I https://alexvagrant.github.io/css/main.css

# 查看响应头中的 Last-Modified 时间
```

## 发布流程建议

```bash
# 1. 清理本地缓存
./clear_cache.sh

# 2. 本地测试
bundle exec jekyll serve

# 3. 提交更改
git add .
git commit -m "更新内容"
git push origin main

# 4. 等待 GitHub Pages 构建（通常 1-2 分钟）
# 5. 强制刷新浏览器查看更新
```

## 预防措施

- ✅ 静态资源已添加时间戳版本控制
- ✅ 使用清理脚本确保本地构建最新
- ✅ 开发时使用开发者工具禁用缓存
- ✅ 发布后等待几分钟让 CDN 缓存更新

## 常见问题

**Q: 为什么推送到 GitHub 后网站还是旧的？**
A: 需要等待 GitHub Pages 构建完成（1-2分钟）+ CDN 缓存更新（10-15分钟）

**Q: 本地预览正常，发布后显示异常？**
A: 清理本地缓存后重新构建：`./clear_cache.sh && bundle exec jekyll serve`

**Q: CSS/JS 更新了但页面没有变化？**
A: 时间戳机制会自动处理，强制刷新浏览器即可（Cmd/Ctrl + Shift + R）

## 调试技巧

```bash
# 查看 Git 提交历史
git log --oneline -5

# 查看 GitHub Pages 部署状态
# 访问：https://github.com/AlexVagrant/AlexVagrant.github.io/actions

# 查看网站响应头
curl -I https://alexvagrant.github.io/
```

