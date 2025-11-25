#!/bin/bash

# Jekyll 缓存清理脚本
# 用于清理 Jekyll 构建缓存，确保生成最新内容

echo "🧹 开始清理 Jekyll 缓存..."

# 清理 Jekyll 缓存目录
if [ -d ".jekyll-cache" ]; then
    rm -rf .jekyll-cache
    echo "✅ 已清理 .jekyll-cache"
fi

# 清理 _site 目录
if [ -d "_site" ]; then
    rm -rf _site
    echo "✅ 已清理 _site"
fi

# 清理 .sass-cache 目录
if [ -d ".sass-cache" ]; then
    rm -rf .sass-cache
    echo "✅ 已清理 .sass-cache"
fi

# 清理 .jekyll-metadata
if [ -f ".jekyll-metadata" ]; then
    rm -f .jekyll-metadata
    echo "✅ 已清理 .jekyll-metadata"
fi

echo ""
echo "✨ 缓存清理完成！"
echo "💡 现在可以运行 'bundle exec jekyll serve' 重新构建站点"

