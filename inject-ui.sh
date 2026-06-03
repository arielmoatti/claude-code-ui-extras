#!/bin/bash
# ── Ensure common binaries are on PATH ────────────────────────────────────
# The SessionStart hook on Windows can invoke bash with a minimal PATH that
# misses curl / node. Add Git-Bash + Node defaults so auto-update works.
for d in "/c/Program Files/Git/usr/bin" "/c/Program Files/Git/mingw64/bin" "/c/Program Files/nodejs" "/usr/bin"; do
  [ -d "$d" ] && case ":$PATH:" in *":$d:"*);; *) PATH="$PATH:$d";; esac
done
export PATH

# ── Changelog (most recent first) ─────────────────────────────────────────
# Single source of truth for version + notes. To release: prepend ONE entry to
# all three arrays. VERSION/UPDATE_NOTE derive from the newest entry, and every
# bump triggers auto-update. The in-webview banner shows only the last 3 entries
# flagged MAJOR=1 (substantial, user-facing fixes); cosmetic/meta tweaks
# (MAJOR=0) still bump the version but stay OUT of the banner. Keep notes free of
# " \ | &  - ASCII apostrophes are auto-swapped to U+2019 so they can't break
# the JS strings.
COMPATIBLE_EXT_VERSION="2.1.159"
CHANGELOG_VERS=(  "1.12.0" "1.11.0" "1.10.0" "1.9.0" "1.8.0" "1.7.0" "1.6.0" "1.5.0" )
CHANGELOG_MAJOR=( "1"      "1"      "0"      "0"     "0"     "0"     "1"     "1"     )
CHANGELOG_NOTES=(
  "בלוקי קוד מופיעים עכשיו ב-50% מהמסך וללא גלילה אופקית (ניתן לכוונון בקובץ ההגדרות)."
  "קליק ימני על מד הקונטקסט מציג פירוט מלא של ניצול חלון ההקשר לפי קטגוריות."
  "הבאנר מציג רק שיפורים מהותיים, לא שינויים קוסמטיים."
  "הבאנר מציג מספר גרסאות אחורה (changelog), לא רק את הנוכחית."
  "קליק ימני על מד הקונטקסט (או על חצי הניווט) מציג את מספר הגרסה הרצה."
  "הודעות עדכון מופיעות כבאנר בתוך הצ'אט במקום בפלט נסתר."
  "אתחול הצ'אט כבר לא נתקע: ה-hook כמעט מיידי, במקום תקיעה של עד 60 שניות אחרי שינה."
  "ההזרקה נטענת מיד ואמינה אחרי שינה/פתיחה מחדש, בלי לדרוש כמה reload-ים."
)
VERSION="${CHANGELOG_VERS[0]}"
UPDATE_NOTE="${CHANGELOG_NOTES[0]}"

# Build a JS array literal of the last 3 MAJOR entries for the banner.
# Apostrophes -> U+2019 so the single-quoted JS strings can't break; notes hold
# no  " \ | &  so this is safe as a sed replacement string.
CHANGELOG_JS="["; _sep=""; _shown=0
for _i in "${!CHANGELOG_VERS[@]}"; do
  [ "$_shown" -ge 3 ] && break
  [ "${CHANGELOG_MAJOR[$_i]}" = "1" ] || continue
  _v="${CHANGELOG_VERS[$_i]}"; _n="${CHANGELOG_NOTES[$_i]//\'/’}"
  CHANGELOG_JS="$CHANGELOG_JS$_sep{v:'$_v',n:'$_n'}"; _sep=","; _shown=$((_shown+1))
done
CHANGELOG_JS="$CHANGELOG_JS]"
REMOTE_URL="https://raw.githubusercontent.com/arielmoatti/claude-code-ui-extras/main/inject-ui.sh"

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

# Read context window flag (default: true)
SHOW_CONTEXT_WINDOW="true"
if [ -f "$CONF_FILE" ]; then
  val="$(grep '^show_context_window=' "$CONF_FILE" | cut -d= -f2-)"
  [ -n "$val" ] && SHOW_CONTEXT_WINDOW="$val"
fi

# Read rate_limit_event diagnostic logging flag (default: false)
RATE_LIMIT_DIAG="false"
if [ -f "$CONF_FILE" ]; then
  val="$(grep '^rate_limit_diag=' "$CONF_FILE" | cut -d= -f2-)"
  [ -n "$val" ] && RATE_LIMIT_DIAG="$val"
fi

# Read auto-update flag (default: true). Kill-switch for users who want to pin.
AUTO_UPDATE="true"
if [ -f "$CONF_FILE" ]; then
  val="$(grep '^auto_update=' "$CONF_FILE" | cut -d= -f2-)"
  [ -n "$val" ] && AUTO_UPDATE="$val"
fi

# Read code-block max width (default: 50%). Caps the width of code/copy blocks
# so they soft-wrap instead of stretching across the full chat and showing a
# horizontal scrollbar. Any CSS width value (50%, 65%, 720px); set to 100% or
# none to disable the cap (full width).
CODE_BLOCK_MAX_WIDTH="50%"
if [ -f "$CONF_FILE" ]; then
  val="$(grep '^code_block_max_width=' "$CONF_FILE" | cut -d= -f2-)"
  [ -n "$val" ] && CODE_BLOCK_MAX_WIDTH="$val"
fi

# ── Signature for the fast path ───────────────────────────────────────
# Short hash of THIS script + the ui.conf values that affect output. It is
# written as a marker line into each patched file; if the marker is already
# present, the per-extension loop skips the whole rebuild (see "Fast path").
# Any edit to the script or the config changes the hash, which invalidates
# the marker and forces a one-time re-patch. Falls back to "always rebuild"
# if md5sum is unavailable.
UI_SIG=""
if command -v md5sum >/dev/null 2>&1; then
  UI_SIG="$(md5sum "${BASH_SOURCE[0]}" 2>/dev/null | cut -c1-10)-$(printf '%s|%s|%s|%s' "$BORDER_COLOR" "$SHOW_CONTEXT_WINDOW" "$RATE_LIMIT_DIAG" "$CODE_BLOCK_MAX_WIDTH" | md5sum 2>/dev/null | cut -c1-6)"
fi
UI_MARKER="Claude UI Extras sig:$UI_SIG"

FOUND=false
for dir in "$HOME/.vscode/extensions"/anthropic.claude-code-*/webview; do
  css="$dir/index.css"
  js="$dir/index.js"
  [ -f "$css" ] || continue
  FOUND=true

  # ── Fast path ────────────────────────────────────────────────────────
  # If both files already carry the current signature marker, there is
  # nothing to do. Skip WITHOUT building the 4.8MB temp + ~5 sed passes
  # (~6s of wall-clock per session, far worse cold after sleep). A blocking
  # SessionStart hook is the #1 cause of the extension's "Subprocess
  # initialization did not complete within 60000ms" timeout, so a
  # near-instant no-op here matters: two greps (~0.05s) replace the whole
  # rebuild.
  if [ -n "$UI_SIG" ] && grep -qF "$UI_MARKER" "$css" 2>/dev/null \
       && { [ ! -f "$js" ] || grep -qF "$UI_MARKER" "$js" 2>/dev/null; }; then
    echo "CLAUDE_UI_OK (already current): $dir"
    continue
  fi

  CHANGED=false


  # ── CSS ──────────────────────────────────────────────────────────────
  # Build the desired file in a SAME-DIR temp, then atomically swap it in
  # ONLY if it differs from what's already on disk. Two reasons:
  #   (a) no "unpatched window" — the old code did `strip in place` then
  #       `append`, leaving a brief moment where the file had no patch. If
  #       the webview read during that gap it loaded raw, unstyled UI.
  #   (b) a no-op resume is now truly no-op — when the file is already
  #       current we DON'T rewrite it at all. So a Reload after sleep loads
  #       the already-patched file instead of racing this hook's rewrite.
  csstmp="$css.uiextras.tmp.$$"
  sed '/\/\* Claude UI Extras Patch Start \*\//,/\/\* Claude UI Extras Patch End \*\//d' "$css" > "$csstmp"
  # Trim trailing blank lines so the rebuild is byte-deterministic. Without
  # this, the heredoc's leading blank line stacks one extra newline per run,
  # and the cmp-skip below would never converge (file grows 1 byte/run).
  sed -i -e :a -e '/^[[:space:]]*$/{$d;N;ba}' "$csstmp"

  cat >> "$csstmp" << CSSPATCH

$CSS_START
/* $UI_MARKER */
[class*="userMessage_"]{border:2px solid $BORDER_COLOR !important;}
.interactive-request .chat-markdown-part{border:2px solid $BORDER_COLOR !important;border-radius:4px;padding:4px 8px;}
[class*="sessionItem_"]{height:auto !important;min-height:28px !important;align-items:flex-start !important;padding-top:4px !important;padding-bottom:4px !important;}
[class*="sessionName_"]{white-space:normal !important;display:-webkit-box !important;-webkit-line-clamp:3 !important;-webkit-box-orient:vertical !important;overflow:hidden !important;}
[class*="userMessage_"] [class*="content_"][class*="collapsed_"]{max-height:175px !important;}
[class*="sessionsButtonText_"]{white-space:normal !important;display:-webkit-box !important;-webkit-line-clamp:3 !important;-webkit-box-orient:vertical !important;overflow:hidden !important;}
[class*="sessionsButtonContent_"]{max-width:unset !important;}
[class*="sessionsButton_"]{max-width:unset !important;}
/* Cap code/copy blocks to a configurable width (default 50%) + soft-wrap: visual wrap only (copy stays one logical line per paragraph), no horizontal scroll, box doesn't span the full chat. Cap the <pre> but keep the WRAPPER full width, so hovering anywhere across the full row still reveals the copy button (the hover lives on the wrapper). Position the button at the block's right edge via calc(100% - width) so it tracks the cap instead of sitting at the window edge. padding-top reserves a strip so the button doesn't cover the first line. Border matches the user-message border ($BORDER_COLOR). Wrapper/button classes are hashed per build, so match by prefix. */
[class*="codeBlockWrapper_"] pre,.chat-markdown-part pre{white-space:pre-wrap !important;overflow-wrap:anywhere !important;overflow-x:visible !important;padding-top:36px !important;max-width:$CODE_BLOCK_MAX_WIDTH !important;}
[class*="codeBlockWrapper_"] code{white-space:pre-wrap !important;overflow-wrap:anywhere !important;}
[class*="codeBlockWrapper_"] [class*="copyButton_"]{right:calc(100% - $CODE_BLOCK_MAX_WIDTH + 20px) !important;border:2px solid $BORDER_COLOR !important;}
$CSS_END
CSSPATCH
  if cmp -s "$csstmp" "$css"; then
    rm -f "$csstmp"
  else
    mv -f "$csstmp" "$css"
    CHANGED=true
  fi

  # ── JS ───────────────────────────────────────────────────────────────
  if [ -f "$js" ]; then
    jstmp="$js.uiextras.tmp.$$"
    sed -e '/\/\* Claude UI Extras Shim Start \*\//,/\/\* Claude UI Extras Shim End \*\//d' \
        -e '/\/\* Claude UI Extras JS Start \*\//,/\/\* Claude UI Extras JS End \*\//d' "$js" > "$jstmp"
    # Trim trailing blank lines (see CSS note above) for a deterministic rebuild.
    sed -i -e :a -e '/^[[:space:]]*$/{$d;N;ba}' "$jstmp"

    cat >> "$jstmp" << 'JSPATCH'

/* Claude UI Extras JS Start */
/* __UI_SIG__ */
;(function(){
  var BORDER_COLOR='__BORDER_COLOR__';
  var BORDER_KEY='claude-ui-extras-border';
  var navIdx=-1;
  var UI_VERSION='__UI_VERSION__';

  /* Billing badge + cost display.
     Source: get_claude_state_response (once on load) → account type
             result io_message (after each response)  → total_cost_usd
             rate_limit_event                         → isUsingOverage (SUB only) */
  var billingLabel='…';
  var isApiMode=false;
  var lastTotalCost=0;       /* last known cumulative session cost */
  var overageBaseline=null;  /* cost at moment overage started; null = not in overage */

  /* get_claude_state_response — determines API vs SUB per window.
     API mode: show "API" badge + $ cost. SUB mode: hide billing badge entirely
     (most users are on SUB — the label is noise); cost badge stays hidden unless overage. */
  window.addEventListener('message',function(e){
    var d=e.data;
    if(!d||d.type!=='from-extension')return;
    var resp=d.message&&d.message.response;
    if(!resp||resp.type!=='get_claude_state_response')return;
    var acct=resp.config&&resp.config.account;
    isApiMode=(acct&&acct.tokenSource==='apiKeyHelper')||false;
    billingLabel=isApiMode?'API':'';
    var b=document.getElementById('claude-ui-billing-badge');
    if(b){
      if(isApiMode){
        b.textContent='API';
        b.style.color='#e8a84f';
        b.style.borderColor='#e8a84f';
        b.style.display='inline-flex';
      } else {
        b.style.display='none';
      }
    }
    /* Show cost badge for API mode, or if SUB with active overage */
    var c=document.getElementById('claude-ui-cost-badge');
    if(c)c.style.display=(isApiMode||overageBaseline!==null)?'inline-flex':'none';
  });

  /* rate_limit_event — detects Extra Usage start/end (SUB mode only).
     v2.1.118+ schema: `status` ("allowed"/"rejected"/…) + `rateLimitType` with
     new `overage` value. The old `utilization>=1` check stopped firing.
     Triggers: either explicit `overage` type, OR `five_hour` + `rejected`.
     DIAG flag: __RATE_LIMIT_DIAG__ — console.logs every event until we confirm the new schema live, then flip off. */
  var RATE_LIMIT_DIAG=__RATE_LIMIT_DIAG__;
  window.addEventListener('message',function(e){
    var d=e.data;
    if(!d||d.type!=='from-extension')return;
    var msg=d.message;
    if(!msg||msg.type!=='io_message')return;
    var m=msg.message;
    if(!m||m.type!=='rate_limit_event')return;
    var info=m.rate_limit_info;
    if(RATE_LIMIT_DIAG)console.log('[claude-ui-extras] rate_limit_event',JSON.stringify(info));
    if(!info||isApiMode)return;
    var c=document.getElementById('claude-ui-cost-badge');
    var inOverage=info.rateLimitType==='overage'||
                  (info.rateLimitType==='five_hour'&&info.status==='rejected');
    if(inOverage&&overageBaseline===null){
      /* Entered overage — capture baseline and show extra cost badge */
      overageBaseline=lastTotalCost;
      if(c){c.style.display='inline-flex';c.style.color='#e05c5c';c.style.borderColor='#e05c5c';c.textContent='extra $0.000';}
    } else if(info.status==='allowed'&&overageBaseline!==null){
      /* Window reset — clear overage */
      overageBaseline=null;
      if(c)c.style.display='none';
    }
  });

  /* result io_message — fired after every response, contains cumulative session cost */
  window.addEventListener('message',function(e){
    var d=e.data;
    if(!d||d.type!=='from-extension')return;
    var msg=d.message;
    if(!msg||msg.type!=='io_message')return;
    var m=msg.message;
    if(!m||m.type!=='result'||typeof m.total_cost_usd!=='number')return;
    lastTotalCost=m.total_cost_usd;
    var c=document.getElementById('claude-ui-cost-badge');
    if(!c)return;
    if(isApiMode){
      c.textContent='$'+m.total_cost_usd.toFixed(3);
    } else if(overageBaseline!==null){
      c.textContent='extra $'+(m.total_cost_usd-overageBaseline).toFixed(3);
    }
  });

  /* Context window badge — per-chat, independent of cost.
     Model captured from assistant io_messages; token usage from result io_message. */
  var SHOW_CONTEXT='__SHOW_CONTEXT_WINDOW__'==='true';
  var currentModel='';

  function fmtTokens(n){
    if(n>=1000000)return (n/1000000).toFixed(1)+'M';
    if(n>=1000)return (n/1000).toFixed(1)+'k';
    return String(n);
  }
  function fmtCap(n){
    if(n>=1000000)return (n/1000000).toFixed(1)+'M';
    return (n/1000)+'k';
  }

  /* Assistant io_message — fired ONCE per API call. message.usage = that call's actual
     context size. Direct display (no max tracking) — assistant usage is accurate and grows
     monotonically as the conversation grows. Duplicate events (streaming partial + final)
     are filtered by comparing against the last displayed value. */
  if(SHOW_CONTEXT){
    var lastCtxRaw=-1;
    window.addEventListener('message',function(e){
      var d=e.data;
      if(!d||d.type!=='from-extension')return;
      var msg=d.message;
      if(!msg||msg.type!=='io_message')return;
      var m=msg.message;
      if(!m||m.type!=='assistant')return;
      var aMsg=m.message;
      if(!aMsg||!aMsg.usage)return;
      if(aMsg.model)currentModel=aMsg.model;
      var u=aMsg.usage;
      /* Exclude output_tokens — they're not in the current window yet, they roll into the
         NEXT call's cache_read. Including them double-counts between turns. */
      var raw=(u.input_tokens||0)+(u.cache_read_input_tokens||0)+(u.cache_creation_input_tokens||0);
      if(raw===0)return;
      if(raw===lastCtxRaw)return; /* dedupe identical streaming events */
      lastCtxRaw=raw;
      /* 1M detection: Opus is always 1M; models with [1m] tag are 1M; usage >200K = 1M */
      var is1M=/opus/i.test(currentModel)||/\[1m\]/i.test(currentModel)||raw>200000;
      var cap=is1M?1000000:200000;
      var pct=Math.round(raw*100/cap);
      var x=document.getElementById('claude-ui-context-badge');
      if(!x)return;
      x.textContent=fmtTokens(raw)+' / '+fmtCap(cap)+' ('+pct+'%)';
      var col=pct>=80?'#f14c4c':pct>=50?'#e8ab3a':'#3dc9b0';
      x.style.color=col;
      x.style.borderColor=col;
    });
  }


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

  /* Shared "UI Extras vX.Y.Z" line. withSep adds a top separator (used when it
     sits under the border toggle); standalone in the context-badge popup. */
  function versionLineEl(withSep){
    var v=document.createElement('div');
    v.textContent='UI Extras v'+UI_VERSION;
    v.style.cssText=(withSep?'border-top:1px solid var(--vscode-menu-separatorBackground,#454545);padding-top:6px;':'')+'opacity:0.6;font-size:11px;white-space:nowrap;cursor:default;';
    return v;
  }

  /* ── Context-usage breakdown (right-click the context badge) ──
     Fires the same get_context_usage RPC the native /context panel uses, through
     the vscode-api handle + channelId captured by the top-of-bundle shim. Degrades
     gracefully to just the version line (with a reason) if the data isn't reachable. */
  var CTX_PALETTE=['#e8a84f','#4f9cf2','#4fc97a','#e8d24f','#b07ff2','#f2674f','#4fd2e8','#e85fb0','#9ad14f','#b58a6a'];

  /* Render a raw model id (claude-opus-4-8[1m]) into a friendly name (Opus 4.8 (1M context)).
     The picker's marketing labels live in the CLI, not the webview, so we format the id
     ourselves - version-resilient, with graceful fallback to the raw id on no match. */
  function prettyModel(id){
    if(!id)return '';
    var s=String(id), is1m=/\[1m\]/i.test(s), base=s.replace(/\[1m\]/i,'');
    var m=base.match(/(opus|sonnet|haiku)-(\d+)-(\d+)/i), name;
    if(m){var fam=m[1].charAt(0).toUpperCase()+m[1].slice(1).toLowerCase();name=fam+' '+m[2]+'.'+m[3];}
    else{name=base.replace(/^claude-/,'');}
    return name+(is1m?' (1M context)':'');
  }

  function fetchContextUsage(cb){
    var api=window.__ccVscodeApi, ch=window.__ccChannelId;
    if(!api){cb(null,'no-api');return;}
    if(ch==null){cb(null,'no-channel');return;}
    var id=Math.random().toString(36).slice(2), done=false;
    function onMsg(e){
      var d=e.data, m=(d&&d.type==='from-extension')?d.message:d;
      if(!m||m.requestId!==id)return;
      done=true; window.removeEventListener('message',onMsg);
      window.__ccDbgResp=m; /* for console inspection while developing */
      var rsp=m.response;
      if(rsp&&rsp.type==='error'){cb(null,'error');return;}
      cb(rsp&&rsp.usage?rsp.usage:null, (rsp&&rsp.error)?'error':null);
    }
    window.addEventListener('message',onMsg);
    setTimeout(function(){if(!done){window.removeEventListener('message',onMsg);cb(null,'timeout');}},5000);
    try{api.postMessage({type:'request',channelId:ch,requestId:id,request:{type:'get_context_usage'}});}
    catch(err){window.removeEventListener('message',onMsg);cb(null,'post-failed');}
  }

  function ctxRow(dotColor,name,tokensTxt,pctTxt){
    var row=document.createElement('div');
    row.style.cssText='display:flex;align-items:center;gap:8px;padding:1px 0;';
    var dot=document.createElement('span');
    dot.style.cssText='width:9px;height:9px;border-radius:2px;flex-shrink:0;'+(dotColor?('background:'+dotColor+';'):'background:transparent;border:1px solid #777;');
    var nm=document.createElement('span'); nm.textContent=name;
    nm.style.cssText='flex:1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;';
    var tk=document.createElement('span'); tk.textContent=tokensTxt;
    tk.style.cssText='min-width:48px;text-align:right;opacity:0.9;';
    var pc=document.createElement('span'); pc.textContent=pctTxt||'';
    pc.style.cssText='min-width:50px;text-align:right;opacity:0.6;';
    row.appendChild(dot);row.appendChild(nm);row.appendChild(tk);row.appendChild(pc);
    return row;
  }

  function ctxSection(c,title,hint,items){
    if(!items||!items.length)return;
    var h=document.createElement('div');
    h.style.cssText='margin-top:8px;padding-top:6px;border-top:1px solid var(--vscode-menu-separatorBackground,#454545);font-size:10px;letter-spacing:0.04em;opacity:0.55;';
    h.textContent=title+(hint?('   '+hint):'');
    c.appendChild(h);
    items.forEach(function(it){ c.appendChild(ctxRow(null,it.name,fmtTokens(it.tokens),'')); });
  }

  function renderCtxBreakdown(c,u){
    c.textContent=''; c.style.opacity='1';
    var max=u.rawMaxTokens||1;
    var h1=document.createElement('div'); h1.textContent=prettyModel(u.model);
    h1.title=u.model||''; /* raw id on hover */
    h1.style.cssText='font-weight:700;margin-bottom:8px;';
    c.appendChild(h1);
    var cats=(u.categories||[]).filter(function(x){return x.tokens>0;});
    var nonFree=cats.filter(function(x){return x.name!=='Free space';});
    var bar=document.createElement('div');
    bar.style.cssText='display:flex;height:6px;border-radius:3px;overflow:hidden;margin-bottom:8px;background:#3a3a3a;';
    nonFree.forEach(function(x,i){
      var seg=document.createElement('div');
      seg.style.cssText='height:100%;width:'+(x.tokens/max*100)+'%;background:'+CTX_PALETTE[i%CTX_PALETTE.length]+';';
      seg.title=x.name+': '+fmtTokens(x.tokens);
      bar.appendChild(seg);
    });
    c.appendChild(bar);
    cats.forEach(function(x){
      var free=x.name==='Free space';
      var idx=nonFree.indexOf(x);
      var p=x.tokens*100/max;
      var ptxt=(p<0.1?'<0.1':p.toFixed(1))+'%';
      var nm=free?'Free space (until auto-compact)':x.name;
      c.appendChild(ctxRow(free?null:CTX_PALETTE[idx%CTX_PALETTE.length], nm, fmtTokens(x.tokens), ptxt));
    });
    var byTok=function(a,b){return (b.tokens||0)-(a.tokens||0);};
    if(u.memoryFiles&&u.memoryFiles.length){
      ctxSection(c,'MEMORY FILES','/memory', u.memoryFiles.slice().sort(byTok).slice(0,5).map(function(m){
        var pth=m.path||''; var base=pth.split(/[\\\/]/).pop()||pth;
        return {name:base, tokens:m.tokens};
      }));
    }
    if(u.agents&&u.agents.length){
      ctxSection(c,'CUSTOM AGENTS','/agents', u.agents.slice().sort(byTok).slice(0,5).map(function(a){
        return {name:a.name||a.id||a.path||'agent', tokens:a.tokens};
      }));
    }
  }

  /* Right-click on the context badge -> full context-usage breakdown (+ version). */
  function showVersionPopup(e){
    e.preventDefault(); e.stopPropagation();
    var ex=document.querySelector('.claude-ui-version-popup');
    if(ex){ex.remove();return;}
    var p=document.createElement('div');
    p.className='claude-ui-version-popup';
    var a=document.getElementById('claude-ui-context-badge');
    var r=a?a.getBoundingClientRect():{top:60,left:window.innerWidth-80};
    p.style.cssText='position:fixed;bottom:'+(window.innerHeight-r.top+6)+'px;left:'+r.left+'px;width:320px;max-height:72vh;overflow-y:auto;background:var(--vscode-menu-background,#2d2d2d);border:1px solid var(--vscode-menu-border,#454545);border-radius:8px;padding:10px 12px;z-index:9999;color:var(--vscode-foreground,#ccc);font-size:12px;box-shadow:0 6px 20px rgba(0,0,0,0.45);';
    var body=document.createElement('div');
    body.textContent='Loading context usage…';
    body.style.cssText='opacity:0.65;';
    p.appendChild(body);
    p.appendChild(versionLineEl(true));
    document.body.appendChild(p);
    function reposition(){
      var rr=p.getBoundingClientRect();
      if(rr.right>window.innerWidth-4)p.style.left=(window.innerWidth-rr.width-4)+'px';
      if(rr.left<4)p.style.left='4px';
    }
    reposition();
    setTimeout(function(){
      document.addEventListener('mousedown',function fn(ev){
        if(!p.contains(ev.target)){p.remove();document.removeEventListener('mousedown',fn,true);}
      },true);
    },0);
    fetchContextUsage(function(u,err){
      if(!document.body.contains(p))return;
      if(!u){
        body.style.opacity='0.65';
        body.textContent = err==='no-channel'
          ? 'Context breakdown unavailable - send a message first (no active request seen yet).'
          : 'Context breakdown unavailable ('+(err||'no data')+').';
        reposition(); return;
      }
      renderCtxBreakdown(body,u);
      reposition();
    });
  }

  function showToggle(e){
    e.preventDefault(); e.stopPropagation();
    var ex=document.querySelector('.claude-ui-border-popup');
    if(ex){ex.remove();return;}
    var p=document.createElement('div');
    p.className='claude-ui-border-popup';
    var nav=document.getElementById('claude-ui-nav');
    var navRect=nav?nav.getBoundingClientRect():{bottom:60,left:window.innerWidth-80};
    p.style.cssText='position:fixed;bottom:'+(window.innerHeight-navRect.top+6)+'px;left:'+navRect.left+'px;background:var(--vscode-menu-background,#2d2d2d);border:1px solid var(--vscode-menu-border,#454545);border-radius:6px;padding:6px 10px;display:flex;flex-direction:column;gap:6px;z-index:9999;font-size:12px;color:var(--vscode-foreground,#ccc);white-space:nowrap;';
    var on=getBorder();
    var row=document.createElement('div');
    row.style.cssText='display:flex;align-items:center;gap:8px;cursor:pointer;';
    var sw=document.createElement('span');
    sw.style.cssText='position:relative;display:inline-block;width:28px;height:16px;flex-shrink:0;';
    var track=document.createElement('span');
    track.style.cssText='position:absolute;inset:0;border-radius:8px;background:'+(on?BORDER_COLOR:'#555')+';transition:background 0.2s;';
    var thumb=document.createElement('span');
    thumb.style.cssText='position:absolute;top:2px;left:'+(on?'14px':'2px')+';width:12px;height:12px;border-radius:50%;background:#fff;transition:left 0.2s;';
    sw.appendChild(track); sw.appendChild(thumb);
    var lbl=document.createElement('span'); lbl.textContent='User message border';
    row.appendChild(sw); row.appendChild(lbl);
    p.appendChild(row);
    p.appendChild(versionLineEl(true));
    document.body.appendChild(p);
    row.addEventListener('click',function(ev){
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

    /* Claude UI Billing Badge — starts hidden; shown as "API" only if state response confirms API mode */
    var badge=document.createElement('span');
    badge.id='claude-ui-billing-badge';
    badge.textContent='';
    badge.title='Account type';
    badge.style.cssText='font-size:10px;font-weight:700;padding:2px 5px;border:1px solid #888;border-radius:3px;line-height:1;cursor:default;margin-left:4px;align-self:center;color:#888;display:none;';
    nav.appendChild(badge);

    /* Cost badge — API mode only, updates after each response */
    var cost=document.createElement('span');
    cost.id='claude-ui-cost-badge';
    cost.textContent='$0.000';
    cost.title='Session cost';
    cost.style.cssText='font-size:10px;font-weight:700;padding:2px 5px;border:1px solid #e8a84f;border-radius:3px;line-height:1;cursor:default;margin-left:4px;align-self:center;color:#e8a84f;display:'+(isApiMode?'inline-flex':'none')+';';
    nav.appendChild(cost);

    /* Context window badge — rightmost; always visible, shows "…" until first result io_message */
    if(SHOW_CONTEXT){
      var ctx=document.createElement('span');
      ctx.id='claude-ui-context-badge';
      ctx.textContent='…';
      ctx.title='Context window usage (per-chat) - right-click: full breakdown';
      ctx.style.cssText='font-size:10px;font-weight:700;padding:2px 5px;border:1px solid #3dc9b0;border-radius:3px;line-height:1;cursor:context-menu;margin-left:4px;align-self:center;color:#3dc9b0;display:inline-flex;';
      ctx.addEventListener('contextmenu',showVersionPopup);
      nav.appendChild(ctx);
    }

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
      var md=htmlToMd(savedDiv).replace(/[\u200F\u200E]/g,'').replace(/\n{3,}/g,'\n\n').trim();
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

  /* Strip invisible RTL/LTR marks from any copy (Ctrl+C or menu Copy) */
  document.addEventListener('copy',function(e){
    var sel=window.getSelection();
    if(!sel||sel.isCollapsed)return;
    var text=sel.toString().replace(/[\u200F\u200E]/g,'');
    e.clipboardData.setData('text/plain',text);
    e.preventDefault();
  },true);
})();

/* ── Update notification banner (in-webview, once per version) ──
   The SessionStart hook's stdout is NOT shown to the user in the VSCode
   extension, so the old "echo the update note" approach was invisible.
   This shows the note in OUR injected DOM instead: a dismissible top
   banner, gated by localStorage so it appears once per new version. */
;(function(){
  var VER='__UI_VERSION__';
  var KEY='claude-ui-extras-seen-version';
  if(!VER||VER.charAt(0)==='_')return;                 /* placeholder not substituted */
  try{ if(localStorage.getItem(KEY)===VER)return; }catch(e){}
  var LOG; try{ LOG=__UI_CHANGELOG__; }catch(e){ LOG=null; }   /* last 3 versions */
  if(!LOG||!LOG.length)LOG=[{v:VER,n:''}];
  var ID='claude-ui-update-banner';
  function mount(){
    if(document.getElementById(ID)||!document.body)return;
    var bar=document.createElement('div');
    bar.id=ID;
    bar.dir='rtl';
    bar.style.cssText='position:fixed;top:0;left:0;right:0;z-index:99999;direction:rtl;text-align:right;display:flex;align-items:flex-start;gap:8px;padding:8px 12px;background:var(--vscode-editorWidget-background,#252526);border-bottom:1px solid var(--vscode-editorWidget-border,#454545);color:var(--vscode-foreground,#ccc);font-size:12px;line-height:1.45;box-shadow:0 2px 6px rgba(0,0,0,0.35);';
    var icon=document.createElement('span');icon.textContent='💡';icon.style.cssText='flex-shrink:0;';
    var txt=document.createElement('div');txt.style.cssText='flex:1;min-width:0;';
    var t1=document.createElement('div');t1.textContent='UI Extras עודכן ל-'+VER;t1.style.cssText='font-weight:700;margin-bottom:3px;';
    txt.appendChild(t1);
    LOG.forEach(function(it){
      var li=document.createElement('div');
      li.textContent='• '+it.v+(it.n?' - '+it.n:'');
      li.style.cssText='opacity:0.85;font-size:11px;margin-top:1px;';
      txt.appendChild(li);
    });
    var x=document.createElement('button');x.textContent='✕';x.title='סגור';
    x.style.cssText='flex-shrink:0;background:none;border:none;color:inherit;cursor:pointer;opacity:0.6;font-size:13px;padding:2px 6px;line-height:1;';
    x.addEventListener('mouseenter',function(){x.style.opacity='1';});
    x.addEventListener('mouseleave',function(){x.style.opacity='0.6';});
    x.addEventListener('click',function(){try{localStorage.setItem(KEY,VER);}catch(e){}bar.remove();});
    bar.appendChild(icon);bar.appendChild(txt);bar.appendChild(x);
    document.body.appendChild(bar);
  }
  mount();
  var n=0,iv=setInterval(function(){mount();if(++n>50||document.getElementById(ID))clearInterval(iv);},200);
})();
JSPATCH

    cat >> "$jstmp" << 'JSEND'
/* Claude UI Extras JS End */
JSEND

    # Substitute border color placeholder
    sed -i "s|__BORDER_COLOR__|$BORDER_COLOR|g" "$jstmp"
    sed -i "s|__SHOW_CONTEXT_WINDOW__|$SHOW_CONTEXT_WINDOW|g" "$jstmp"
    sed -i "s|__RATE_LIMIT_DIAG__|$RATE_LIMIT_DIAG|g" "$jstmp"
    sed -i "s|__UI_SIG__|$UI_MARKER|g" "$jstmp"
    sed -i "s|__UI_VERSION__|$VERSION|g" "$jstmp"
    # The changelog JS array (built up top; apostrophes already U+2019-swapped,
    # no  " \ | &  in notes, so it's safe as a sed replacement string).
    sed -i "s|__UI_CHANGELOG__|$CHANGELOG_JS|g" "$jstmp"

    # Prepend the vscode-api capture shim to the very TOP of the bundle so it runs
    # before the app's one-shot acquireVsCodeApi() call. It wraps that call to stash
    # the api handle (window.__ccVscodeApi) and sniffs the live channelId off outgoing
    # requests (window.__ccChannelId) - both needed to fire get_context_usage from the
    # injected code (context-breakdown popup). No placeholders, so no sed pass needed.
    shimtmp="$js.uiextras.shim.$$"
    cat > "$shimtmp" << 'JSSHIM'
/* Claude UI Extras Shim Start */
;(function(){try{if(window.__ccShimInstalled)return;window.__ccShimInstalled=true;var orig=window.acquireVsCodeApi;if(typeof orig==='function'){window.acquireVsCodeApi=function(){var api=orig.apply(this,arguments);try{window.__ccVscodeApi=api;}catch(_){}return api;};}window.addEventListener('message',function(e){try{var d=e.data;if(!d)return;var m=(d.type==='from-extension')?d.message:d;if(m&&m.type==='io_message'&&m.channelId!=null)window.__ccChannelId=m.channelId;}catch(_){}},false);}catch(_){}})();
/* Claude UI Extras Shim End */
JSSHIM
    cat "$jstmp" >> "$shimtmp"
    mv -f "$shimtmp" "$jstmp"

    # NOTE: the v1.4.0 "Unhandled case: [object Object]" / QB1 throw patch was
    # removed in v1.5.0. Anthropic refactored that assert-never throw out of the
    # webview bundle somewhere between 2.1.141 and 2.1.158 (issue #58897, closed)
    # - the literal "Unhandled case" string no longer exists in the bundle, so
    # the patch had become a dead no-op. Full patch is preserved in git history
    # (tag v1.4.0) and in PROJECTS.md, to re-apply if the crash class returns
    # under a new helper name.
    if cmp -s "$jstmp" "$js"; then
      rm -f "$jstmp"
    else
      mv -f "$jstmp" "$js"
      CHANGED=true
    fi
  fi

  if [ "$CHANGED" = true ]; then
    echo "CLAUDE_UI_PATCHED: $dir"
  else
    echo "CLAUDE_UI_OK (already current): $dir"
  fi
done

if [ "$FOUND" = false ]; then
  echo "Claude Code extension not found."
  exit 1
fi

# ── Install bypass-claude-dir.js hook script ──────────────────────────────
BYPASS_HOOK_PATH="$HOME/.claude/scripts/bypass-claude-dir.js"
mkdir -p "$(dirname "$BYPASS_HOOK_PATH")"
cat > "$BYPASS_HOOK_PATH" << 'BYPASSHOOK'
/*
 * bypass-claude-dir.js — PermissionRequest hook
 * Auto-approves Edit/Write/Bash on .claude/ paths, but only when session
 * is already in bypassPermissions mode. Respects plan/ask/acceptEdits.
 * Works around anthropics/claude-code#39523.
 */
let d = '';
process.stdin.on('data', c => d += c);
process.stdin.on('end', () => {
  try {
    const input = JSON.parse(d);
    const tool = input.tool_name || '';
    const ti = input.tool_input || {};
    const filePath = ti.file_path || '';
    const command = ti.command || '';
    const isEditLike = /^(Edit|Write|MultiEdit|NotebookEdit)$/.test(tool);
    const isBash = tool === 'Bash';
    const shouldAllow = (isEditLike && filePath.includes('.claude'))
                     || (isBash && command.includes('.claude'));
    const inBypass = input.permission_mode === 'bypassPermissions';
    if (shouldAllow && inBypass) {
      process.stdout.write(JSON.stringify({
        hookSpecificOutput: {
          hookEventName: 'PermissionRequest',
          decision: { behavior: 'allow' }
        }
      }));
    }
  } catch (e) {}
});
BYPASSHOOK
echo "BYPASS_HOOK_WRITTEN: $BYPASS_HOOK_PATH"

# ── Register hooks in ~/.claude/settings.json ────────────────────────────
SETTINGS="$HOME/.claude/settings.json"
HOOK_CMD="bash $SCRIPT_DIR/inject-ui.sh"
SCRIPT_ID="inject-ui.sh"
BYPASS_CMD="node $BYPASS_HOOK_PATH"

SETTINGS_PATH="$SETTINGS" HOOK_CMD="$HOOK_CMD" SCRIPT_ID="$SCRIPT_ID" BYPASS_CMD="$BYPASS_CMD" \
node -e "
var fs = require('fs');
var p = process.env.SETTINGS_PATH;
var cmd = process.env.HOOK_CMD;
var id = process.env.SCRIPT_ID;
var bypassCmd = process.env.BYPASS_CMD;
var s = {};
if (fs.existsSync(p)) { try { s = JSON.parse(fs.readFileSync(p,'utf8')); } catch(e) {} }
if (!s.hooks) s.hooks = {};

// SessionStart hook (UI injection)
if (!s.hooks.SessionStart) s.hooks.SessionStart = [];
var sessionAlready = s.hooks.SessionStart.some(function(h){
  return h.hooks && h.hooks.some(function(hh){ return hh.command && hh.command.indexOf(id) !== -1; });
});
if (!sessionAlready) {
  s.hooks.SessionStart.push({ hooks: [{ type: 'command', command: cmd }] });
  console.log('SessionStart hook registered:', cmd);
} else {
  console.log('SessionStart hook already registered');
}

// PermissionRequest hook (bypass .claude/ guard)
if (!s.hooks.PermissionRequest) s.hooks.PermissionRequest = [];
var permAlready = s.hooks.PermissionRequest.some(function(h){
  return h.hooks && h.hooks.some(function(hh){ return hh.command && hh.command.indexOf('bypass-claude-dir.js') !== -1; });
});
if (!permAlready) {
  s.hooks.PermissionRequest.push({
    matcher: 'Edit|Write|MultiEdit|NotebookEdit|Bash',
    hooks: [{ type: 'command', command: bypassCmd }]
  });
  console.log('PermissionRequest hook registered:', bypassCmd);
} else {
  console.log('PermissionRequest hook already registered');
}

fs.writeFileSync(p, JSON.stringify(s, null, 2), 'utf8');
" 2>/dev/null || echo "Note: could not register hooks (node not found)"

# ── Auto-update (once per 24h) ────────────────────────────────────────────
# Runs at the END of the script so the Hebrew notification is the LAST thing
# printed — Claude Code's SessionStart renderer only shows the last few lines,
# so placing the update message last guarantees users see it.
# Fetches remote script, compares VERSION. If newer and .sh syntax-valid,
# replaces self on disk for the next session. No exec — today's session
# already ran the old injection; new code takes effect on next Reload Window.
# Fails open on any error.
if [ "$AUTO_UPDATE" = "true" ]; then
  STATE_FILE="$SCRIPT_DIR/.ui-extras-last-update-check"
  NOW=$(date +%s)
  LAST=0
  [ -f "$STATE_FILE" ] && LAST=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
  if [ $((NOW - LAST)) -gt 86400 ]; then
    echo "$NOW" > "$STATE_FILE"
    TMP="$(mktemp 2>/dev/null || echo "/tmp/inject-ui-$$.sh")"
    if curl -fsSL --connect-timeout 3 --max-time 8 -o "$TMP" "$REMOTE_URL" 2>/dev/null; then
      REMOTE_VER="$(grep -m1 '^VERSION=' "$TMP" | sed 's/^VERSION="\(.*\)".*/\1/')"
      REMOTE_NOTE="$(grep -m1 '^UPDATE_NOTE=' "$TMP" | sed 's/^UPDATE_NOTE="\(.*\)".*/\1/')"
      REMOTE_EXT_VER="$(grep -m1 '^COMPATIBLE_EXT_VERSION=' "$TMP" | sed 's/^COMPATIBLE_EXT_VERSION="\(.*\)".*/\1/')"
      if [ -n "$REMOTE_VER" ] && [ "$REMOTE_VER" != "$VERSION" ] && bash -n "$TMP" 2>/dev/null; then
        cp "$TMP" "${BASH_SOURCE[0]}"
        echo "💡 חבילת שיפורי ממשק לקלוד קוד (נבדק מול הגרסה: $REMOTE_EXT_VER)"
        echo "תיקון חדש: $REMOTE_NOTE"
        echo "משהו לא עובד? פשוט לעשות Reload."
      fi
    fi
    rm -f "$TMP"
  fi
fi
