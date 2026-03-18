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
    footer.insertBefore(nav,addBtn);
  }

  applyBorder();
  setInterval(injectNav, 200);
})();
/* Claude UI Extras JS End */
JSPATCH

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
