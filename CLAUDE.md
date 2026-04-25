# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库性质

这是 **GitHub Pages 个人博客的已生成静态产物**，部署在自定义域名 `sbrave.cn`（见 `CNAME`）。

仓库**只包含渲染后的 HTML/CSS/JS/图片**，没有源 Markdown、没有构建脚本、没有 `package.json` / `_config.yml` / `Makefile`。博客背后的生成器是作者自研的 Go 框架 **gobog**，源码托管在 [`github.com/sbraveyoung/gobog`](https://github.com/sbraveyoung/gobog)（参见 `/post/77a668/index.html` "我的博客演进历程"）。**生成器源码不在本仓库内**——本仓库只放产物。

实际后果：
- 没有 build / lint / test 命令可以在本仓库运行；任何 "运行测试" 的请求都不适用。如需重新生成，需克隆 `gobog` 仓库并使用其工作流。
- 本地预览只能用任意静态文件服务器（例如 `python3 -m http.server` 在仓库根目录运行后访问 `http://localhost:8000`）。
- 修改内容时必须**直接编辑生成后的 HTML**——除非同时同步更新 gobog 中对应的 Markdown 源文件，否则下次生成器全量重生成会覆盖手工修改。

## 目录结构与页面模板

仓库根布局：
- `index.html` — 首页，**手动维护的文章/专栏索引**。
- `about/index.html` — 关于页面。
- `post/<hash>/index.html` — 单篇文章；`<hash>` 是 7 或 8 位十六进制不透明 ID。
- `post/<series-hash>/<post-hash>/index.html` — 专栏（系列）下的子文章；专栏的 `index.html` 自身是一个子文章列表页。
- `css/` — `home.css`（列表页样式）、`main.css`（文章页样式）、`prism.css`（代码高亮）、`resume.css`。
- `js/prism.js` — 代码高亮。
- `image/` — 所有文章引用的图片资源。
- `CNAME` — GitHub Pages 自定义域名（`sbrave.cn`），不要随意改动。
- `.nojekyll` — 空文件，告诉 GitHub Pages 跳过 Jekyll 处理，按纯静态文件直接发布。
- `robots.txt` — 允许全部抓取，并指向 `sitemap.xml`。
- `sitemap.xml` — 全站 URL 索引，由 find 列出所有 `index.html` 路径生成，新增 / 删除文章时需要同步更新。
- `atom.xml` — RSS 订阅源，对应首页 25 条顶层入口。新增 / 删除顶层条目时需要同步更新。
- `404.html` — 自定义 404 页，套列表页模板。

页面分两类模板，添加 / 修改时必须保持一致：

1. **列表页模板**（首页、专栏索引页）
   - 引入 `/css/home.css` + Bootstrap 3.1.1 CDN。
   - 主体是 `<ul class="list-group">`，每个条目 `<li class="list-group-item title"><a href="/post/<hash>" tag="export">标题</a></li>`。
   - 顶部导航 `Smart的个人博客` / `博客` / `Github` / `About`。

2. **文章页模板**（`about/`、所有 `post/.../index.html` 内容页）
   - 引入 `/css/main.css` + `/css/prism.css` + `/js/prism.js`。
   - 头部包含 MathJax CDN（用于公式）和移动端 UA 检测脚本。
   - 正文包裹在 `<div class="inner">` 中，标题用 `<h2>`。

两类模板都包含 Google Analytics（`UA-78070816-3`）和 footer（`Copyright © sbrave 2021`、ICP 备案号 `陕ICP备16005721号-1`）。修改任何页面时**保持这些片段原样**，不要"清理"看似无用的 CDN 引入或注释。

## 添加 / 修改文章时的关键约束

- 新文章目录名必须是新的不透明 hash（与生成器一致）；不要使用语义化 slug，否则与现有命名风格不符。
- 新增文章后，**必须手动同步以下入口**：
  1. `index.html` 中的 `<ul class="list-group">`（顶级文章 / 专栏入口）；
  2. 如果是专栏内文章，还要同步该专栏的 `index.html`；
  3. `sitemap.xml` 加 `<url>` 条目（顶级和子文章都要）；
  4. 顶级新条目额外加到 `atom.xml` 的 `<entry>`（专栏内子文章按惯例不加 atom）。
- 文章内的相对链接均以 `/post/<hash>` / `/image/<file>` 等绝对路径写入，不要改成相对路径。
- 页面底部的 `anti-baidu-latest.min.js` 引入是有意为之（防百度抓取），不要删除。

## Git 与发布

- 默认分支：`master`。GitHub Pages 直接从分支根目录发布，**push 即上线**——任何修改都会立即出现在 `sbrave.cn`。
- `.git/config` 中 `gc.auto = 0`（关闭自动 GC），不要改。
- 仓库历史的 commit message 普遍是简短的 `update` / `update index.html` / `add a image` 之类；遵循该风格即可，无需写约定式提交。

## 当前任务分支

按照上层指令，本会话的开发分支为 `claude/add-claude-documentation-1w50z`，所有改动需要 commit 到该分支并 push 到 origin。不要直接推到 `master`。
