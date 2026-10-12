#!/usr/bin/env python3
"""Check all themes, local routes and assets in a gobog static export."""
import os, sys
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
root=Path(sys.argv[1] if len(sys.argv)>1 else '_dist').resolve()
if not root.is_dir():raise SystemExit('Missing export directory: '+str(root))
errors=set();warnings=set();used=set()
class Scan(HTMLParser):
    def __init__(self,page): super().__init__(convert_charrefs=True);self.page=page
    def handle_starttag(self,tag,attrs):
        for key,value in attrs:
            if key not in ('src','href','action') or not value: continue
            u=urlsplit(value)
            if u.scheme=='file' or u.hostname in {'localhost','127.0.0.1'}:
                warnings.add((str(self.page.relative_to(root)),value));continue
            if u.scheme or u.netloc or value.startswith('#'):continue
            # Search assets are generated after rendering; the pre-index check
            # still verifies every renderer-owned asset and article route.
            if u.path.startswith('/_pagefind/'):continue
            target=(root/unquote(u.path).lstrip('/') if u.path.startswith('/') else self.page.parent/unquote(u.path)).resolve()
            try:target.relative_to(root)
            except ValueError:errors.add((str(self.page.relative_to(root)),value));continue
            if target.is_file() or (target/'index.html').is_file():used.add(target);continue
            issue=(str(self.page.relative_to(root)),value)
            # Missing historic images remain visible warnings. Broken page or
            # theme/JS/CSS routes block publishing.
            if tag=='img' or target.suffix.lower() in {'.png','.jpg','.jpeg','.gif','.webp','.bmp','.avif'}:warnings.add(issue)
            else:errors.add(issue)
    handle_startendtag=handle_starttag
for page in root.rglob('*.html'):
    parser=Scan(page);parser.feed(page.read_text())
for page,u in sorted(errors):print('::error::'+page+': missing internal route/asset '+u)
for page,u in sorted(warnings):print('::warning::'+page+': missing image/local URL '+u)
print(f'check-export: {len(errors)} errors; {len(warnings)} image/local URL warnings')
raise SystemExit(1 if errors else 0)
