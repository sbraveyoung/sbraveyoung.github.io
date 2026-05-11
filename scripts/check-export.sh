#!/usr/bin/env bash
# scripts/check-export.sh — sanity-checks the rendered site before commit.
#
# Three passes, all best-effort warnings (no exit 1 on findings — the
# deploy continues either way):
#
#   1. Dead internal links   — every /post/* and /image/* href / src in
#                              the HTML must resolve to a file in the
#                              export tree.
#   2. Orphan resources       — files under <out>/image/ that no HTML page
#                              references (i.e., we ship bytes nobody
#                              uses).
#   3. Suspicious URLs       — file:///, localhost, 127.0.0.1 references
#                              that almost certainly slipped in from a
#                              local editor (Typora, etc.).
#
# Usage: scripts/check-export.sh <export-dir>
#
# The script is plain bash + grep + find + sort + comm — no go / node
# install needed inside the workflow.

set -u

OUT="${1:-_dist}"
if [ ! -d "$OUT" ]; then
  echo "::error::check-export: directory '$OUT' does not exist"
  exit 2
fi

# Total counts for the GH Action summary.
dead_links=0
orphan_resources=0
suspicious=0

# Helper: stream every HTML page with <!-- ... --> comments stripped out
# so URLs that the author commented out (Typora's `<!-- ![](file:///...) -->`
# remnants, deliberately-disabled images, etc.) don't fire false positives.
# Multi-line comments are flattened by feeding the page through awk first.
strip_html_comments() {
  awk 'BEGIN { in_c = 0 }
  {
    line = $0
    while (1) {
      if (in_c) {
        end = index(line, "-->")
        if (end == 0) { line = ""; break }
        line = substr(line, end + 3)
        in_c = 0
      } else {
        start = index(line, "<!--")
        if (start == 0) break
        # check if the comment closes on the same line
        rest = substr(line, start + 4)
        end = index(rest, "-->")
        if (end > 0) {
          line = substr(line, 1, start - 1) substr(rest, end + 3)
        } else {
          line = substr(line, 1, start - 1)
          in_c = 1
          break
        }
      }
    }
    print line
  }' "$1"
}

# --------------------------------------------------------------------
# 1. Dead internal links
# --------------------------------------------------------------------
# Collect every href / src that starts with /post/ or /image/ across all
# HTML pages. For each one, resolve to a file path in $OUT and check
# existence.
echo "::group::1/3 dead-link scan"
tmp_links=$(mktemp)
find "$OUT" -name '*.html' -print0 | while IFS= read -r -d '' f; do
  strip_html_comments "$f"
done \
  | grep -oE '(href|src)="(/post/[^"#?]*|/image/[^"#?]*)"' \
  | sed -E 's/.*="([^"]+)".*/\1/' \
  | sort -u > "$tmp_links"

while IFS= read -r url; do
  [ -z "$url" ] && continue
  # /image/foo.png → check the file directly.
  # /post/foo/bar  → check both <out>/post/foo/bar/index.html and
  #                  <out>/post/foo/bar (a few legacy routes have no
  #                  trailing slash equivalent).
  rel="${url#/}"
  if [ -f "$OUT/$rel" ] || [ -f "$OUT/$rel/index.html" ] || [ -d "$OUT/$rel" ]; then
    continue
  fi
  echo "::warning::dead internal link: $url"
  dead_links=$((dead_links + 1))
done < "$tmp_links"
rm -f "$tmp_links"
echo "::endgroup::"

# --------------------------------------------------------------------
# 2. Orphan resources under /image/
# --------------------------------------------------------------------
echo "::group::2/3 orphan-resource scan"
tmp_present=$(mktemp)
tmp_used=$(mktemp)
(cd "$OUT" && find image -type f 2>/dev/null) \
  | sort -u > "$tmp_present"

# Every basename referenced from HTML (comments stripped), normalized
# to image/<basename>.
find "$OUT" -name '*.html' -print0 | while IFS= read -r -d '' f; do
  strip_html_comments "$f"
done \
  | grep -oE '(href|src)="[^"]+\.(png|jpe?g|gif|webp|bmp|svg|avif)"' \
  | sed -E 's|.*/([^/"]+)".*|\1|' \
  | awk '{print "image/" $0}' \
  | sort -u > "$tmp_used"

# Diff: present minus used = orphans (only basename-comparable to keep
# the script portable across nested vs. flat layouts).
tmp_present_base=$(mktemp)
sed -E 's|.*/||' "$tmp_present" | sort -u > "$tmp_present_base"
tmp_used_base=$(mktemp)
sed -E 's|.*/||' "$tmp_used" | sort -u > "$tmp_used_base"
while IFS= read -r f; do
  [ -z "$f" ] && continue
  # Skip the favicon / icon emitted by the theme — they're referenced
  # from `<link rel="icon">` (`/css/favicon.svg`), not /image/.
  case "$f" in favicon.*|icon.*) continue ;; esac
  echo "::warning::orphan resource: image/$f"
  orphan_resources=$((orphan_resources + 1))
done < <(comm -23 "$tmp_present_base" "$tmp_used_base")
rm -f "$tmp_present" "$tmp_used" "$tmp_present_base" "$tmp_used_base"
echo "::endgroup::"

# --------------------------------------------------------------------
# 3. Suspicious local-only URLs leaking into HTML
# --------------------------------------------------------------------
echo "::group::3/3 suspicious-URL scan"
while IFS= read -r line; do
  [ -z "$line" ] && continue
  echo "::warning::suspicious URL leaked into HTML: $line"
  suspicious=$((suspicious + 1))
done < <(find "$OUT" -name '*.html' -print0 | while IFS= read -r -d '' f; do
    strip_html_comments "$f"
  done \
    | grep -oE '(file:///|https?://localhost|https?://127\.0\.0\.1)[^"<>'\'' ]*' \
    | sort -u)
echo "::endgroup::"

# --------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------
total=$((dead_links + orphan_resources + suspicious))
if [ "$total" -eq 0 ]; then
  echo "check-export: clean — no dead links, orphan resources, or suspicious URLs"
else
  echo "check-export summary:"
  echo "  dead internal links:  $dead_links"
  echo "  orphan resources:     $orphan_resources"
  echo "  suspicious URLs:      $suspicious"
fi

# Non-fatal by default. Set CHECK_EXPORT_FATAL=1 in the workflow if you
# want findings to fail the build.
if [ "${CHECK_EXPORT_FATAL:-0}" = "1" ] && [ "$total" -gt 0 ]; then
  echo "::error::check-export: $total issue(s) and CHECK_EXPORT_FATAL=1"
  exit 1
fi
exit 0
