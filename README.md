# sbraveyoung.github.io

Public mirror of <https://sbrave.cn>. The repo is **machine-managed** —
its contents are rebuilt on every push to [`sbraveyoung/blog`](https://github.com/sbraveyoung/blog)
and committed by the deploy workflow.

## How a publish happens

```
sbraveyoung/blog (source markdown)
   │
   │  push to master  →  .github/workflows/deploy.yml
   │                     calls repository_dispatch (event_type=blog-update)
   ▼
sbraveyoung/sbraveyoung.github.io (this repo)
   │
   │  .github/workflows/deploy.yml runs:
   │    1. checkout sbraveyoung/blog        (markdown source)
   │    2. checkout sbraveyoung/gobog       (renderer)
   │    3. go build _gobog/src              (build binary)
   │    4. gobog -config _gobog.toml \
   │             -export _dist              (render site)
   │    5. replace tree with _dist/         (commit ready)
   │    6. git commit + git push            (publish)
   │
   ▼
GitHub Pages serves this repo at sbrave.cn
```

## Customizing

Open [`_gobog.json`](./_gobog.json) and edit:

| Key           | Effect                                                |
| ------------- | ----------------------------------------------------- |
| `theme`       | One of `minimal` / `sepia` / `ocean`. Picks the look. |
| `domain`      | Used for canonical URLs and `<link rel="canonical">`. |
| `title`       | Shown in the header and `<title>`.                    |
| `subtitle`    | Tagline under the title on the home page.             |
| `author`      | Used in the atom feed and the footer.                 |
| `description` | Used for `<meta name="description">` and OG tags.     |
| `cname`       | Written to `CNAME` in the deploy output.              |

Commit + push the change. The deploy workflow re-renders the whole site
with the new value.

You can also rebuild on demand from the **Actions** tab → **Deploy** →
**Run workflow** (Theme input lets you preview a theme without editing
`_gobog.json`).

## Triggers

The deploy workflow runs on:

- `repository_dispatch` (event type `blog-update`) — fired by the blog repo.
- `workflow_dispatch` — manual.
- A nightly schedule (06:00 UTC) — safety net in case a webhook misses.

## Required secrets

| Name      | What                                              |
| --------- | ------------------------------------------------- |
| `GH_PAT`  | Fine-grained PAT, Contents: Read on `sbraveyoung/blog` and `sbraveyoung/gobog`, Read & Write on this repo. |

When all three repos are public, the default `GITHUB_TOKEN` is used as a
fallback for read access; `GH_PAT` is still recommended so the workflow
can be moved to private repos without ceremony.
