# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal technical blog built with Jekyll and deployed to GitHub Pages. The site uses Chinese language for content.

## Common Commands

```bash
# Start local development server
make serve

# Start server with drafts visible
make serve-drafts

# Build the site
make build

# Deploy to GitHub (clean, build, commit, push)
make deploy

# Clean all caches
make clean

# Create a new post
rake post title="Post Title"

# Create a new draft
rake draft title="Draft Title"
```

## Architecture

- **Framework**: Jekyll with Kramdown markdown
- **Syntax Highlighting**: Rouge (configured in `_config.yml`)
- **Plugins**: jekyll-redirect-from, jekyll-feed, jekyll-seo-tag, jekyll-archives
- **Collections**: `category` and `tag` collections with custom permalinks
- **Permalinks**: `/posts/:title` format
- **Timezone**: Asia/Shanghai

## Key Directories

- `_posts/` - Published blog posts (markdown files with frontmatter)
- `_drafts/` - Unpublished drafts
- `_layouts/` - Page templates (post, page, home, archive, category, tag)
- `_includes/` - Reusable components (head, menu_item, post_list, etc.)
- `_sass/` - SCSS stylesheets
- `category/` - Generated category pages
- `tag/` - Generated tag pages
- `css/` - Compiled CSS files
- `api/` - API-related files

## Post Frontmatter Format

```yaml
---
layout: post
title: "Post Title"
date: YYYY-MM-DD
category:
tags:
---
```

## Cache Handling

The site has automatic cache-busting for CSS (timestamp-based versioning). If updates don't appear:
1. Force refresh browser (Cmd/Ctrl + Shift + R)
2. Run `make clean` to clear local Jekyll cache
3. Wait 10-15 minutes for GitHub CDN to update

## Style Customization

Generate custom syntax highlighting CSS:
```bash
rougify style monokai > css/syntax.css
```
