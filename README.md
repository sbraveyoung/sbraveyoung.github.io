# 字里行间 · GitHub Pages 构建配置

线上博客：[sbrave.cn](https://sbrave.cn)。

本仓库维护站点配置 `_gobog.json`、构建部署工作流和验证脚本。Markdown 内容来自私有 `sbraveyoung/blog`，渲染器来自固定 SHA 的 `sbraveyoung/gobog`。构建完成后生成文件通过 Pages artifact 部署；HTML、搜索索引与主题资源不再提交回 Git。

- 编辑 `_gobog.json` 调整主题、作者、域名或固定渲染器版本。
- 源码仓库 push 通过 `blog-update` 触发部署；也可手动运行 Deploy。
- 工作流验证渲染器、链接、资源与 Pagefind 索引，再部署 Pages。
- Actions Summary 记录源码 SHA、渲染器 SHA 与主题。
- 使用与发表开关详见 [管线手册](https://github.com/sbraveyoung/gobog/blob/master/docs/publishing-pipeline.zh-CN.md)。

隐藏文章与目录不会进入新的公开构建，但过去公开的内容可能仍在 Git 历史和外部缓存中。本次调整保留历史，不进行强制历史重写。
