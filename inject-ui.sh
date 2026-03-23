#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/ui.conf"
CSS_START="/* Claude UI Extras Patch Start */"
CSS_END="/* Claude UI Extras Patch End */"
JS_START="/* Claude UI Extras JS Start */"
JS_END="/* Claude UI Extras JS End */"

# Read border color from config or use default (soft coral, 50% opacity)
BORDER_COLOR="rgba(249,131,131,0.5)"
if [ -f "$CONF_FILE" ]; then
  val="$(grep '^border_color=' "$CONF_FILE" | cut -d= -f2-)"
  [ -n "$val" ] && BORDER_COLOR="$val"
fi


FOUND=false
for dir in "$HOME/.vscode/extensions"/anthropic.claude-code-*/webview; do
  css="$dir/index.css"
  js="$dir/index.js"
  [ -f "$css" ] || continue
  FOUND=true
  CHANGED=false

  # ── CSS ──────────────────────────────────────────────────────────────
  if grep -qF "$CSS_START" "$css"; then
    sed -i '/\/\* Claude UI Extras Patch Start \*\//,/\/\* Claude UI Extras Patch End \*\//d' "$css"
  fi

  cat >> "$css" << CSSPATCH

$CSS_START
[class*="userMessage_"]{border:2px solid $BORDER_COLOR !important;}
.interactive-request .chat-markdown-part{border:2px solid $BORDER_COLOR !important;border-radius:4px;padding:4px 8px;}
[class*="sessionItem_"]{height:auto !important;min-height:28px !important;align-items:flex-start !important;padding-top:4px !important;padding-bottom:4px !important;}
[class*="sessionName_"]{white-space:normal !important;display:-webkit-box !important;-webkit-line-clamp:3 !important;-webkit-box-orient:vertical !important;overflow:hidden !important;}
[class*="userMessage_"] [class*="content_"][class*="collapsed_"]{max-height:175px !important;}
[class*="sessionsButtonText_"]{white-space:normal !important;display:-webkit-box !important;-webkit-line-clamp:3 !important;-webkit-box-orient:vertical !important;overflow:hidden !important;}
[class*="sessionsButtonContent_"]{max-width:unset !important;}
[class*="sessionsButton_"]{max-width:unset !important;}
$CSS_END
CSSPATCH
  CHANGED=true

  # ── JS ───────────────────────────────────────────────────────────────
  if [ -f "$js" ]; then
    if grep -qF "$JS_START" "$js"; then
      sed -i '/\/\* Claude UI Extras JS Start \*\//,/\/\* Claude UI Extras JS End \*\//d' "$js"
    fi
    cat >> "$js" << 'JSPATCH'

/* Claude UI Extras JS Start */
;(function(){
  var BORDER_COLOR='__BORDER_COLOR__';
  var BORDER_KEY='claude-ui-extras-border';
  var navIdx=-1;

  /* Billing badge + cost display.
     Source: get_claude_state_response (once on load) → account type
             result io_message (after each response)  → total_cost_usd (API only) */
  var billingLabel='…';
  var isApiMode=false;

  /* get_claude_state_response — determines API vs SUB per window */
  window.addEventListener('message',function(e){
    var d=e.data;
    if(!d||d.type!=='from-extension')return;
    var resp=d.message&&d.message.response;
    if(!resp||resp.type!=='get_claude_state_response')return;
    var acct=resp.config&&resp.config.account;
    isApiMode=(acct&&acct.tokenSource==='apiKeyHelper')||false;
    billingLabel=isApiMode?'API':'SUB';
    var b=document.getElementById('claude-ui-billing-badge');
    if(b){b.textContent=billingLabel;b.style.color=isApiMode?'#e8a84f':'#7ec8e3';b.style.borderColor=isApiMode?'#e8a84f':'#7ec8e3';}
    /* Show/hide cost badge based on account type */
    var c=document.getElementById('claude-ui-cost-badge');
    if(c)c.style.display=isApiMode?'inline-flex':'none';
  });

  /* result io_message — fired after every response, contains cumulative session cost */
  window.addEventListener('message',function(e){
    var d=e.data;
    if(!d||d.type!=='from-extension')return;
    var msg=d.message;
    if(!msg||msg.type!=='io_message')return;
    var m=msg.message;
    if(!m||m.type!=='result'||typeof m.total_cost_usd!=='number')return;
    var c=document.getElementById('claude-ui-cost-badge');
    if(c)c.textContent='$'+m.total_cost_usd.toFixed(3);
  });

  function getBorder(){ return localStorage.getItem(BORDER_KEY)!=='false'; }
  function setBorder(on){ localStorage.setItem(BORDER_KEY,String(on)); applyBorder(); }

  function applyBorder(){
    var ID='claude-ui-extras-border-style';
    var el=document.getElementById(ID);
    if(!getBorder()){
      if(!el){el=document.createElement('style');el.id=ID;document.head.appendChild(el);}
      el.textContent='[class*="userMessage_"]{border:none !important;}.interactive-request .chat-markdown-part{border:none !important;}';
    } else { if(el)el.remove(); }
  }

  function navigate(dir){
    var msgs=Array.from(document.querySelectorAll('[class*="message_"][class*="userMessageContainer_"]'));
    if(!msgs.length)return;
    if(navIdx<0||navIdx>=msgs.length) navIdx=dir===-1?msgs.length-1:0;
    else { navIdx+=dir; if(navIdx<0)navIdx=0; if(navIdx>=msgs.length)navIdx=msgs.length-1; }
    var t=msgs[navIdx];
    t.scrollIntoView({behavior:'smooth',block:'center'});
    t.classList.remove('claude-ui-highlight');
    void t.offsetWidth;
    t.classList.add('claude-ui-highlight');
    t.addEventListener('animationend',function(){t.classList.remove('claude-ui-highlight');},{once:true});
  }

  function showToggle(e){
    e.preventDefault(); e.stopPropagation();
    var ex=document.querySelector('.claude-ui-border-popup');
    if(ex){ex.remove();return;}
    var p=document.createElement('div');
    p.className='claude-ui-border-popup';
    var nav=document.getElementById('claude-ui-nav');
    var navRect=nav?nav.getBoundingClientRect():{bottom:60,left:window.innerWidth-80};
    p.style.cssText='position:fixed;bottom:'+(window.innerHeight-navRect.top+6)+'px;left:'+navRect.left+'px;background:var(--vscode-menu-background,#2d2d2d);border:1px solid var(--vscode-menu-border,#454545);border-radius:6px;padding:6px 10px;display:flex;align-items:center;gap:8px;z-index:9999;cursor:pointer;font-size:12px;color:var(--vscode-foreground,#ccc);white-space:nowrap;';
    var on=getBorder();
    var sw=document.createElement('span');
    sw.style.cssText='position:relative;display:inline-block;width:28px;height:16px;flex-shrink:0;';
    var track=document.createElement('span');
    track.style.cssText='position:absolute;inset:0;border-radius:8px;background:'+(on?BORDER_COLOR:'#555')+';transition:background 0.2s;';
    var thumb=document.createElement('span');
    thumb.style.cssText='position:absolute;top:2px;left:'+(on?'14px':'2px')+';width:12px;height:12px;border-radius:50%;background:#fff;transition:left 0.2s;';
    sw.appendChild(track); sw.appendChild(thumb);
    var lbl=document.createElement('span'); lbl.textContent='User message border';
    p.appendChild(sw); p.appendChild(lbl);
    document.body.appendChild(p);
    p.addEventListener('click',function(ev){
      ev.preventDefault(); ev.stopPropagation();
      var v=!getBorder(); setBorder(v);
      track.style.background=v?BORDER_COLOR:'#555';
      thumb.style.left=v?'14px':'2px';
    });
    setTimeout(function(){
      document.addEventListener('mousedown',function fn(ev){
        if(!p.contains(ev.target)){p.remove();document.removeEventListener('mousedown',fn,true);}
      },true);
    },0);
  }

  function injectNav(){
    if(document.getElementById('claude-ui-nav'))return;
    var footer=document.querySelector('[class*="inputFooter_"]');
    if(!footer)return;
    var addBtn=footer.querySelector('[class*="addButtonContainer_"]');
    if(!addBtn)return;

    if(!document.getElementById('claude-ui-nav-style')){
      var st=document.createElement('style');
      st.id='claude-ui-nav-style';
      st.textContent=
        '@keyframes claude-ui-pulse{0%{outline:3px solid '+BORDER_COLOR+';outline-offset:2px;}100%{outline:3px solid transparent;outline-offset:6px;}}'+
        '.claude-ui-highlight{animation:claude-ui-pulse 0.6s ease-out;}'+
        '#claude-ui-nav{display:flex;align-items:center;gap:2px;margin-right:4px;}'+
        '#claude-ui-nav button{background:none;border:none;cursor:pointer;padding:4px;border-radius:4px;color:var(--vscode-foreground,#ccc);opacity:0.7;display:flex;align-items:center;}'+
        '#claude-ui-nav button:hover{opacity:1;background:var(--vscode-toolbar-hoverBackground,rgba(255,255,255,0.1));}'+
        '#claude-ui-nav button svg{width:14px;height:14px;}';
      document.head.appendChild(st);
    }

    var nav=document.createElement('div'); nav.id='claude-ui-nav';
    nav.addEventListener('mousedown',function(e){e.preventDefault();});

    var UP='<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M4.5 15.75l7.5-7.5 7.5 7.5"/></svg>';
    var DN='<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5"/></svg>';
    var END='<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M19.5 8.25l-7.5 7.5-7.5-7.5"/><line x1="4.5" y1="19.5" x2="19.5" y2="19.5" stroke-linecap="round"/></svg>';

    var up=document.createElement('button'); up.title='Previous message (↑)'; up.innerHTML=UP;
    up.addEventListener('click',function(e){e.preventDefault();e.stopPropagation();navigate(-1);});
    up.addEventListener('contextmenu',showToggle);

    var dn=document.createElement('button'); dn.title='Next message (↓)'; dn.innerHTML=DN;
    dn.addEventListener('click',function(e){e.preventDefault();e.stopPropagation();navigate(1);});
    dn.addEventListener('contextmenu',showToggle);

    var end=document.createElement('button'); end.title='Jump to bottom (⤓)'; end.innerHTML=END;
    end.addEventListener('click',function(e){
      e.preventDefault(); e.stopPropagation();
      var scroller=document.querySelector('[class*="messagesContainer_"]');
      if(scroller&&scroller.lastElementChild){scroller.lastElementChild.scrollIntoView({behavior:'smooth',block:'end'});}
      var msgs=document.querySelectorAll('[class*="message_"][class*="userMessageContainer_"]');
      navIdx=msgs.length-1;
    });
    end.addEventListener('contextmenu',showToggle);

    nav.appendChild(up); nav.appendChild(dn); nav.appendChild(end);

    /* Claude UI Billing Badge — text updated live from update_state message */
    var badge=document.createElement('span');
    badge.id='claude-ui-billing-badge';
    badge.textContent=billingLabel;
    badge.title='Account type';
    badge.style.cssText='font-size:10px;font-weight:700;padding:2px 5px;border:1px solid #888;border-radius:3px;line-height:1;cursor:default;margin-left:4px;align-self:center;color:#888;';
    nav.appendChild(badge);

    /* Cost badge — API mode only, updates after each response */
    var cost=document.createElement('span');
    cost.id='claude-ui-cost-badge';
    cost.textContent='$0.000';
    cost.title='Session cost (API)';
    cost.style.cssText='font-size:10px;font-weight:700;padding:2px 5px;border:1px solid #e8a84f;border-radius:3px;line-height:1;cursor:default;margin-left:4px;align-self:center;color:#e8a84f;display:'+(isApiMode?'inline-flex':'none')+';';
    nav.appendChild(cost);

    footer.insertBefore(nav,addBtn);
  }

  applyBorder();
  setInterval(injectNav, 200);
})();

/* ── Copy as Markdown context menu ── */
;(function(){
  function htmlToMd(node){
    if(node.nodeType===3)return node.textContent;
    if(node.nodeType!==1)return '';
    var tag=node.tagName.toLowerCase();
    if(tag==='script'||tag==='style')return '';
    var inner=Array.from(node.childNodes).map(htmlToMd).join('');
    switch(tag){
      case 'h1':return'\n# '+inner.trim()+'\n\n';
      case 'h2':return'\n## '+inner.trim()+'\n\n';
      case 'h3':return'\n### '+inner.trim()+'\n\n';
      case 'h4':return'\n#### '+inner.trim()+'\n\n';
      case 'h5':return'\n##### '+inner.trim()+'\n\n';
      case 'h6':return'\n###### '+inner.trim()+'\n\n';
      case 'strong':case 'b':return'**'+inner+'**';
      case 'em':case 'i':return'*'+inner+'*';
      case 'code':
        if(node.parentElement&&node.parentElement.tagName.toLowerCase()==='pre')return inner;
        return'`'+inner+'`';
      case 'pre':{
        var ce=node.querySelector('code');
        var lang='';
        if(ce){var m=(ce.className||'').match(/language-(\w+)/);if(m)lang=m[1];}
        return'\n```'+lang+'\n'+(ce?ce.textContent:node.textContent)+'\n```\n\n';
      }
      case 'p':return inner.trim()+'\n\n';
      case 'br':return'\n';
      case 'hr':return'\n---\n\n';
      case 'a':return'['+inner+']('+(node.getAttribute('href')||'')+')';
      case 'img':return'!['+(node.getAttribute('alt')||'')+']('+(node.getAttribute('src')||'')+')';
      case 'li':return inner.trim();
      case 'ul':return'\n'+Array.from(node.children).map(function(li){return'- '+htmlToMd(li).trim();}).join('\n')+'\n\n';
      case 'ol':return'\n'+Array.from(node.children).map(function(li,i){return(i+1)+'. '+htmlToMd(li).trim();}).join('\n')+'\n\n';
      case 'blockquote':return inner.trim().split('\n').map(function(l){return'> '+l;}).join('\n')+'\n\n';
      case 'tr':{var cells=Array.from(node.children).map(function(td){return htmlToMd(td).trim();});return'| '+cells.join(' | ')+' |\n';}
      case 'thead':case 'tbody':case 'table':case 'th':case 'td':return inner;
      default:return inner;
    }
  }

  function getSelDiv(){
    var sel=window.getSelection();
    if(!sel||sel.rangeCount===0||sel.isCollapsed)return null;
    var div=document.createElement('div');
    for(var i=0;i<sel.rangeCount;i++)div.appendChild(sel.getRangeAt(i).cloneContents());
    return div;
  }

  function showCopyMenu(x,y){
    var old=document.getElementById('claude-copy-menu');
    if(old)old.remove();
    var savedDiv=getSelDiv();
    if(!savedDiv)return;

    var menu=document.createElement('div');
    menu.id='claude-copy-menu';
    menu.style.cssText='position:fixed;left:'+x+'px;top:'+y+'px;background:var(--vscode-menu-background,#2d2d2d);border:1px solid var(--vscode-menu-border,#454545);border-radius:4px;padding:4px 0;z-index:99999;min-width:180px;box-shadow:0 2px 8px rgba(0,0,0,0.5);font-size:13px;font-family:var(--vscode-font-family,sans-serif);';

    function item(label,hint,fn){
      var el=document.createElement('div');
      el.style.cssText='display:flex;justify-content:space-between;align-items:center;padding:5px 16px;cursor:pointer;color:var(--vscode-menu-foreground,#ccc);gap:24px;white-space:nowrap;';
      var sp=document.createElement('span');sp.textContent=label;
      var sh=document.createElement('span');sh.textContent=hint;sh.style.cssText='opacity:0.5;font-size:11px;';
      el.appendChild(sp);el.appendChild(sh);
      el.addEventListener('mouseenter',function(){el.style.background='var(--vscode-menu-selectionBackground,#094771)';el.style.color='var(--vscode-menu-selectionForeground,#fff)';});
      el.addEventListener('mouseleave',function(){el.style.background='';el.style.color='var(--vscode-menu-foreground,#ccc)';});
      el.addEventListener('mousedown',function(e){e.preventDefault();});
      el.addEventListener('click',function(e){e.stopPropagation();menu.remove();fn();});
      return el;
    }

    menu.appendChild(item('Copy','Ctrl+C',function(){document.execCommand('copy');}));
    menu.appendChild(item('Copy as Markdown','',function(){
      var md=htmlToMd(savedDiv).replace(/\n{3,}/g,'\n\n').trim();
      navigator.clipboard.writeText(md);
    }));

    document.body.appendChild(menu);
    var r=menu.getBoundingClientRect();
    if(r.right>window.innerWidth)menu.style.left=(window.innerWidth-r.width-8)+'px';
    if(r.bottom>window.innerHeight)menu.style.top=(y-r.height)+'px';

    setTimeout(function(){
      document.addEventListener('mousedown',function fn(e){
        if(!menu.contains(e.target)){menu.remove();document.removeEventListener('mousedown',fn,true);}
      },true);
    },0);
  }

  document.addEventListener('contextmenu',function(e){
    var sel=window.getSelection();
    if(!sel||sel.isCollapsed)return;
    e.preventDefault();
    showCopyMenu(e.clientX,e.clientY);
  },true);
})();
JSPATCH

    cat >> "$js" << 'JSEND'
/* Claude UI Extras JS End */
JSEND

    # Substitute border color placeholder
    sed -i "s|__BORDER_COLOR__|$BORDER_COLOR|g" "$js"
    CHANGED=true
  fi

  if [ "$CHANGED" = true ]; then
    echo "CLAUDE_UI_PATCHED: $dir"
  fi
done

if [ "$FOUND" = false ]; then
  echo "Claude Code extension not found."
  exit 1
fi

# ── Register SessionStart hook in ~/.claude/settings.json ────────────────────
SETTINGS="$HOME/.claude/settings.json"
HOOK_CMD="bash $SCRIPT_DIR/inject-ui.sh"
SCRIPT_ID="inject-ui.sh"

SETTINGS_PATH="$SETTINGS" HOOK_CMD="$HOOK_CMD" SCRIPT_ID="$SCRIPT_ID" \
node -e "
var fs = require('fs');
var p = process.env.SETTINGS_PATH;
var cmd = process.env.HOOK_CMD;
var id = process.env.SCRIPT_ID;
var s = {};
if (fs.existsSync(p)) { try { s = JSON.parse(fs.readFileSync(p,'utf8')); } catch(e) {} }
if (!s.hooks) s.hooks = {};
if (!s.hooks.SessionStart) s.hooks.SessionStart = [];
var already = s.hooks.SessionStart.some(function(h){
  return h.hooks && h.hooks.some(function(hh){ return hh.command && hh.command.indexOf(id) !== -1; });
});
if (!already) {
  s.hooks.SessionStart.push({ hooks: [{ type: 'command', command: cmd }] });
  fs.writeFileSync(p, JSON.stringify(s, null, 2), 'utf8');
  console.log('Hook registered:', cmd);
} else {
  console.log('Hook already registered');
}
" 2>/dev/null || echo "Note: could not register hook (node not found)"
