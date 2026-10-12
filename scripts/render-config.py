#!/usr/bin/env python3
"""Write valid TOML from the site's single JSON configuration."""
import json, os, re, sys
from pathlib import Path
cfg = json.loads(Path(sys.argv[1] if len(sys.argv)>1 else '_gobog.json').read_text())
theme = os.environ.get('THEME_OVERRIDE') or cfg.get('theme', 'minimal')
if theme not in {'minimal','sepia','ocean','letter','press','tufte'}:
    raise SystemExit('Unknown theme: ' + theme)
ref=cfg.get('gobog_ref','be2204ca19974e03b29359b34a5f0c15deb4ccde')
if not isinstance(ref,str) or not re.fullmatch('[0-9a-f]{40}',ref):
    raise SystemExit('gobog_ref must be a full commit SHA')
def quote(value):
    if not isinstance(value,str): raise ValueError('Site metadata must be strings')
    return json.dumps(value,ensure_ascii=False)
blog={k:cfg.get(k,default) for k,default in {'domain':'https://sbrave.cn','title':'sbraveyoung · 字里行间','subtitle':'阅读 · 实践 · 思考','description':'一个程序员的笔记本','author':'sbraveyoung','cname':''}.items()}
blog.update(theme='_gobog/themes/'+theme,source='_blog')
lines=['[blog]']+[k+' = '+quote(v) for k,v in blog.items()]+['include_drafts = false','include_hidden = false','[http]','addr = ""','addrs = ""','[data]','dir = "_data"','[comments]']
comments=cfg.get('comments',{})
enabled=comments.get('enabled',False)
if not isinstance(enabled,bool):raise ValueError('comments.enabled must be Boolean')
lines.append('enabled = '+str(enabled).lower())
for k,default in {'provider':'giscus','repo':'','repo_id':'','category':'General','category_id':'','mapping':'pathname','reactions_enabled':'1','input_position':'bottom'}.items():
    lines.append(k+' = '+quote(comments.get(k,default)))
Path(sys.argv[2] if len(sys.argv)>2 else '_gobog.toml').write_text('\n'.join(lines)+'\n')
if os.environ.get('GITHUB_OUTPUT'):
    with open(os.environ['GITHUB_OUTPUT'],'a') as f:f.write('theme='+theme+'\ngobog_ref='+ref+'\n')
