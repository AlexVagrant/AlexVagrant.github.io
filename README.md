# AlexVagrant Blog

个人技术博客，使用 Jekyll 构建并部署在 GitHub Pages。

## 快速开始

### 本地开发

```bash
# 清理缓存并启动服务器
make serve

# 或者
bundle exec jekyll serve
```

打开浏览器访问 `http://localhost:4000`

### 创建新文章

```bash
rake post title="文章标题"
```

### 清理缓存

```bash
# 使用 Makefile（推荐）
make clean

# 或使用清理脚本
./clear_cache.sh
```

### 发布到 GitHub

```bash
# 一键发布（清理、构建、提交、推送）
make deploy

# 或手动操作
git add .
git commit -m "更新内容"
git push origin main
```

## 缓存处理

GitHub Pages 有多层缓存机制，如果更新后网站没有变化：

1. **强制刷新浏览器**: `Cmd + Shift + R` (Mac) 或 `Ctrl + Shift + R` (Windows/Linux)
2. **清理本地缓存**: `make clean`
3. **等待 CDN 更新**: GitHub CDN 缓存约 10-15 分钟

详细说明请查看 [CACHE_GUIDE.md](./CACHE_GUIDE.md)

## 可用命令

```bash
make clean   # 清理所有缓存
make serve   # 启动本地服务器
make build   # 构建站点
make deploy  # 发布到 GitHub
make help    # 显示帮助信息
```

## 样式定制

查看支持的代码高亮样式：

```bash
rougify help style
```

生成新的高亮样式 CSS：

```bash
rougify style monokai > css/syntax.css
```
