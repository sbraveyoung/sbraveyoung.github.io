# sbraveyoung.github.io

[English](./README.md) | **[简体中文](./README.zh-CN.md)**

<https://sbrave.cn> 的公开镜像。这个仓库是**机器托管**的——主分支的所有内容
都会在每次 `sbraveyoung/blog` 有 push 时被 deploy workflow 整体替换。

## 一次发布是怎么发生的

```
sbraveyoung/blog（markdown 原始内容）
   │
   │  push 到 master  →  .github/workflows/deploy.yml
   │                     调用 repository_dispatch（event_type=blog-update）
   ▼
sbraveyoung/sbraveyoung.github.io（本仓库）
   │
   │  .github/workflows/deploy.yml 跑起来：
   │    1. checkout sbraveyoung/blog        （markdown 内容）
   │    2. checkout sbraveyoung/gobog       （渲染引擎）
   │    3. go build _gobog/src              （编译二进制）
   │    4. gobog -config _gobog.toml \
   │             -export _dist              （渲染整站）
   │    5. 用 _dist/ 替换工作树              （准备好提交）
   │    6. git commit + git push            （发布）
   │
   ▼
GitHub Pages 把这个仓库伺服在 sbrave.cn
```

## 自定义

打开 [`_gobog.json`](./_gobog.json) 改这些字段：

| 键名          | 作用                                                  |
| ------------- | ----------------------------------------------------- |
| `theme`       | `minimal` / `sepia` / `ocean` 三选一，决定整站观感。  |
| `domain`      | 用作 canonical URL 和 `<link rel="canonical">`。       |
| `title`       | 站点标题，显示在 header 和 `<title>` 里。              |
| `subtitle`    | 首页标题下方的 tagline。                              |
| `author`      | 用于 atom feed 和页脚。                               |
| `description` | 写入 `<meta name="description">` 和 OG 标签。         |
| `cname`       | 写入导出目录里的 `CNAME` 文件。                       |

改完 commit + push 即可，deploy workflow 会用新配置整站重渲染。

也可以在 **Actions** 页面 → **Deploy** → **Run workflow** 手动跑，
其中 Theme 输入框允许你不动 `_gobog.json` 临时预览另一套主题。

## 触发器

deploy workflow 在以下三种情况会跑：

- `repository_dispatch`（事件类型 `blog-update`）——blog 仓库 push 时主动通知。
- `workflow_dispatch`——手动。
- 每天凌晨 06:00 UTC 兜底跑一次，防止某次 webhook 没送达。

## 必需的 Secret

| 名称      | 作用                                              |
| --------- | ------------------------------------------------- |
| `GH_PAT`  | Fine-grained PAT，对 `sbraveyoung/blog` 和 `sbraveyoung/gobog` 有 Contents: Read 权限，对本仓库有 Read & Write 权限。 |

如果三个仓库都是 public，默认的 `GITHUB_TOKEN` 也能 fallback 到读权限；
配 `GH_PAT` 主要是为了让 workflow 在任何一侧切到 private 时依然能工作。
