.PHONY: clean serve build deploy help

# 默认目标
.DEFAULT_GOAL := help

## 清理所有缓存
clean:
	@echo "🧹 清理缓存..."
	@rm -rf _site .jekyll-cache .sass-cache .jekyll-metadata
	@echo "✨ 缓存清理完成！"

## 启动本地服务器
serve: clean
	@echo "🚀 启动 Jekyll 服务器..."
	@bundle exec jekyll serve

## 启动本地服务器（包含草稿）
serve-drafts: clean
	@echo "🚀 启动 Jekyll 服务器（包含草稿）..."
	@bundle exec jekyll serve --drafts

## 构建站点
build: clean
	@echo "🔨 构建站点..."
	@bundle exec jekyll build
	@echo "✅ 构建完成！"

## 发布到 GitHub（清理、构建、提交、推送）
deploy: clean build
	@echo "📦 准备发布..."
	@git add .
	@read -p "输入提交信息: " msg; \
	git commit -m "$$msg"
	@git push origin main
	@echo "🎉 发布成功！"
	@echo "💡 提示：等待 1-2 分钟后访问网站查看更新"

## 显示帮助信息
help:
	@echo "📚 可用命令："
	@echo ""
	@echo "  make clean        - 清理所有缓存"
	@echo "  make serve        - 清理缓存并启动本地服务器"
	@echo "  make serve-drafts - 清理缓存并启动本地服务器（包含草稿）"
	@echo "  make build        - 清理缓存并构建站点"
	@echo "  make deploy       - 清理、构建、提交并推送到 GitHub"
	@echo "  make help         - 显示此帮助信息"
	@echo ""
	@echo "💡 开发流程："
	@echo "  1. make serve-drafts # 本地预览（包含草稿）"
	@echo "  2. 编辑内容"
	@echo "  3. make deploy       # 发布到 GitHub"

