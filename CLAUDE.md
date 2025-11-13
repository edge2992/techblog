# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Hugo-based tech blog using the Noteworthy theme. The blog is deployed on Netlify and focuses on technical content in Japanese.

## Key Commands

### Development
- Local development server: `hugo server`
- Build for production: `hugo --gc --minify`

### Content Management
- Create new post: `hugo new posts/<FILE_NAME>.md`
- Generate OGP image: `sh ./makeogp.sh <path-to-markdown-file>`

## Project Structure

### Core Directories
- `content/posts/`: Blog post content in Markdown format
- `content/about/`: About page content
- `static/`: Static assets (images, fonts, favicons)
- `layouts/`: Custom Hugo layout overrides
- `themes/noteworthy/`: Hugo theme files
- `public/`: Generated site output (not tracked in git)

### Configuration Files
- `config.toml`: Hugo site configuration with theme settings, menus, and social links
- `netlify.toml`: Netlify deployment configuration with Hugo version and build commands
- `tcardgen.yaml`: Configuration for OGP image generation

### Content Organization
- Posts are organized by date in filenames (e.g., `20241218_isucon14_overcached.md`)
- Static images stored in `static/img/` with subdirectories for specific posts
- OGP images auto-generated and stored in `static/img/og/`

## Theme Customization
- Uses Noteworthy theme with custom CSS in `layouts/partials/head.html`
- Custom fonts (Kinto Sans) in `static/fonts/kinto/`
- Mermaid diagram support via custom render hook

## Deployment
- Netlify auto-deploys from git repository
- Hugo version 0.142.0 specified in netlify.toml
- Production builds use `--gc --minify --enableGitInfo` flags