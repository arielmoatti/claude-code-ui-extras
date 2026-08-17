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
COMPATIBLE_EXT_VERSION="2.1.233"
CHANGELOG_VERS=(  "1.29.0" "1.28.0" "1.27.0" "1.26.0" "1.25.0" "1.24.0" "1.23.0" "1.22.0" "1.21.0" "1.20.0" "1.19.0" "1.18.0" "1.17.1" "1.17.0" "1.16.0" "1.15.0" "1.14.0" "1.13.0" "1.12.0" "1.11.0" "1.10.0" "1.9.0" "1.8.0" "1.7.0" "1.6.0" "1.5.0" )
CHANGELOG_MAJOR=( "1"      "1"      "1"      "1"      "0"      "1"      "1"      "0"      "1"      "1"      "0"      "1"      "0"      "0"      "0"      "1"      "0"      "0"      "1"      "1"      "0"      "0"     "0"     "0"     "1"     "1"     )
CHANGELOG_NOTES=(
  "תוקנו שני מרוצים בין חבילת ה-UI לחבילת העברית, ששתיהן נטענות בפתיחת כל צאט. הראשון: שתיהן ערכו את אותו קובץ של התוסף באותו רגע, ולכן לפעמים אחת נטענה והשנייה לא, והיה צריך כמה Reload עד ששתיהן תפסו. עכשיו הן ממתינות אחת לשנייה. השני, נדיר אבל הרסני: כשקובץ ההגדרות settings.json לא היה ניתן לקריאה לרגע, הרישום העצמי כתב אותו מחדש מאפס ומחק את כל שאר ה-hooks, את המודל ואת ההרשאות. עכשיו הוא מדלג במקרה כזה, כותב רק כשבאמת השתנה משהו, והכתיבה עצמה אטומית."
  "מתחת לכל הודעה מופיעה עכשיו השעה: מתי שלחתם את הפרומפט ומתי קלוד סיים לענות, מדויק עד השנייה. שימושי כשגוללים אחורה בשיחה ארוכה ורוצים לדעת מתי כל דבר קרה. השעות נשמרות כל עוד החלון פתוח ומתאפסות בטעינה מחדש, ואפשר לכבות אותן עם show_message_time בקובץ ההגדרות."
  "המתגים בתפריט ההגדרות (Thinking, Switch models when a message is flagged, Remote control) נראו אותו דבר דלוקים וכבויים, אפור על אפור, והדרך היחידה לדעת הייתה באיזה צד יושב העיגול הקטן. עכשיו מתג דלוק מקבל את הצבע הבולט של ערכת הנושא שלכם, אז רואים במבט אחד מה דלוק ומה לא."
  "קליק על קישור בצ'אט לקובץ PDF (וכן תמונה, וורד, אקסל, זיפ, וידאו) פותח אותו עכשיו בתוכנה שמוגדרת לו במערכת, למשל אקרובט, במקום להציג ג'יבריש בעורך הטקסט. הסיבה: הצ'אט שולח כל קובץ לפקודה שמכריחה עורך טקסט ועוקפת את התוסף הרשום לסיומת, ולכן קבצים בינאריים נשלחים עכשיו בערוץ של קישורי אינטרנט, זה שמעביר למערכת ההפעלה."
  "מד הקונטקסט משנה צבע עכשיו בארבע מדרגות במקום שלוש: תורקיז עד 30%, צהוב 30-40%, כתום 40-50%, אדום מעל 50% - התראה מוקדמת יותר על מילוי חלון ההקשר."
  "הודעות המערכת האוטומטיות (task-notification וכו') כבר לא מתנהגות כמו פרומפט שכתבת: הוסרו מהן כפתור ה-Collapse שלנו, כפתור ה-Rewind הנייטיב וההיצמדות לראש המסך. הן נשארות פסיביות ומעומעמות."
  "קליק ימני על קישור לקובץ ואז Copy Link מעתיק עכשיו את הנתיב המלא של הקובץ (כולל כונן), מוכן להדבקה בסייר הקבצים או בטרמינל - במקום הנתיב היחסי הגולמי שלא היה שמיש מחוץ ל-VSCode. קישורי אינטרנט נשארים כמו שהם."
  "תיקון לתווית ה-Alt מ-1.21.0: היא מתעדכנת עכשיו אמינות גם אחרי שימוש ראשון (לחיצת Alt ב-Windows גנבה את פוקוס המקלדת לתפריט של VSCode, ומאז המקלדת לא הגיעה לצ׳אט; עכשיו המצב מסונכרן גם מתנועת העכבר)."
  "קיפול הודעות משתמש עובד עכשיו פר-הודעה (Collapse/Expand במקום Minimize all, עם Alt+קליק לקיפול הכל), הודעות מערכת אוטומטיות כבר לא מוצגות עם מסגרת כאילו הן פרומפט שלך, ובאנר העדכון לא חוזר לקפוץ אחרי שנסגר בפתיחת חלון חדש."
  "עדכונים נפרסים עכשיו תוך דקות במקום עד יממה: בדיקת העדכון רצה ברקע בכל פתיחת צ'אט בלי להאט אותו, וכשעדכון ירד והותקן - קלוד מודיע בצ'אט שצריך Reload כדי להפעיל אותו."
  "שורת הגרסה (קליק ימני על מד הקונטקסט או על חצי הניווט) מציגה עכשיו גם את גרסת חבילת העברית, כשהיא מותקנת."
  "ריחוף על הודעת משתמש מציג כפתור Minimize all שמקפל את כל ההודעות לשורה אחת (Expand all מחזיר). ההצללה וכפתור Show more מופיעים רק כשבאמת נחתך תוכן, ו-Show less כבר לא בורח לפינה השמאלית בהודעות בעברית."
  "באנר העדכון שקט עכשיו גם כשהגרסה שנראתה חדשה מהאחרונה בלוג (השוואת גרסאות אמיתית במקום השוואה מדויקת)."
  "מד הקונטקסט מזהה עכשיו את מודל Fable 5 החדש: חלון 1M מזוהה נכון גם מתחת ל-200K, והשם מוצג יפה בפירוט."
  "עודכנה גרסת התאימות שנבדקה ל-Claude Code 2.1.169."
  "כפתור מזעור ליד כפתור הסגירה בתיבת השאלה - מקפל אותה לשורה אחת כדי לקרוא את התשובה שמאחוריה, ולחיצה נוספת פותחת מחדש."
  "הבאנר קופץ עכשיו רק כשיש שיפור מהותי חדש מאז הפעם האחרונה, ולא בכל בליטת גרסה."
  "הוסר הטלאי שעקף את חלוניות ההרשאה של .claude - אנתרופיק תיקנו את הבאג, הוא כבר לא נחוץ."
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

# Read question-minimize flag (default: true). Adds a − button next to the ✕ in
# the AskUserQuestion panel that collapses it to its one-line header, so the
# answer floating behind the panel becomes readable; click again (⬜) to restore.
QUESTION_MINIMIZE="true"
if [ -f "$CONF_FILE" ]; then
  val="$(grep '^question_minimize=' "$CONF_FILE" | cut -d= -f2-)"
  [ -n "$val" ] && QUESTION_MINIMIZE="$val"
fi

# Read user-message collapse height in px (default: 175, ~8 lines; native is 60).
# Used BOTH as the displayed max-height (CSS) and as the overflow-decision
# threshold (bundle patch below) - keeping the two aligned is what prevents the
# "fade + Show more on a fully-visible message" glitch.
USER_MSG_MAX_H="175"
if [ -f "$CONF_FILE" ]; then
  val="$(grep '^user_msg_max_height=' "$CONF_FILE" | cut -d= -f2- | tr -cd '0-9')"
  [ -n "$val" ] && USER_MSG_MAX_H="$val"
fi

# Read user-message minimize flag (default: true). Adds a hover "minimize"
# button on every user message that folds it to a single line; hovering the
# folded line shows "expand" to restore.
USER_MSG_MINIMIZE="true"
if [ -f "$CONF_FILE" ]; then
  val="$(grep '^user_msg_minimize=' "$CONF_FILE" | cut -d= -f2-)"
  [ -n "$val" ] && USER_MSG_MINIMIZE="$val"
fi

# Read message time-stamp flag (default: true). Puts the wall-clock time
# under every block: when a prompt was sent, when an answer finished.
SHOW_MESSAGE_TIME="true"
if [ -f "$CONF_FILE" ]; then
  val="$(grep '^show_message_time=' "$CONF_FILE" | cut -d= -f2-)"
  [ -n "$val" ] && SHOW_MESSAGE_TIME="$val"
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
  UI_SIG="$(md5sum "${BASH_SOURCE[0]}" 2>/dev/null | cut -c1-10)-$(printf '%s|%s|%s|%s|%s|%s|%s|%s' "$BORDER_COLOR" "$SHOW_CONTEXT_WINDOW" "$RATE_LIMIT_DIAG" "$CODE_BLOCK_MAX_WIDTH" "$QUESTION_MINIMIZE" "$USER_MSG_MAX_H" "$USER_MSG_MINIMIZE" "$SHOW_MESSAGE_TIME" | md5sum 2>/dev/null | cut -c1-6)"
fi
UI_MARKER="Claude UI Extras sig:$UI_SIG"

# ── Cross-package patch lock ─────────────────────────────────────────────
# The UI pack and the Hebrew RTL pack are BOTH SessionStart hooks, they fire
# at the same instant, and they patch the SAME index.js / index.css. Each one
# strips only its own marker block and appends its own, so two concurrent runs
# are a textbook lost update: both read the file, both build their temp from
# that same snapshot, and whoever mv-s last silently drops the other pack.
# That is the long-standing "one pack loaded, the other did not, reload a few
# times until both stick" symptom. One lock shared by both scripts serialises
# them. mkdir is the primitive because it is atomic, and HOME is the one path
# both scripts agree on wherever each happens to be installed.
#
# Fails OPEN. If the lock cannot be taken inside the ceiling we patch anyway -
# a SessionStart hook must never hold up the session. Worst case is the old
# behaviour, never worse than it.
PATCH_LOCK="$HOME/.claude/.cc-webview-patch.lock"
LOCK_HELD=false
mkdir -p "$HOME/.claude" 2>/dev/null
_lock_try=0
while [ "$_lock_try" -lt 50 ]; do          # 50 x 0.2s = 10s ceiling
  if mkdir "$PATCH_LOCK" 2>/dev/null; then LOCK_HELD=true; break; fi
  # Break a lock orphaned by a killed run (older than 60s).
  _lock_age=$(( $(date +%s) - $(stat -c %Y "$PATCH_LOCK" 2>/dev/null || date +%s) ))
  if [ "$_lock_age" -gt 60 ]; then rm -rf "$PATCH_LOCK" 2>/dev/null; continue; fi
  sleep 0.2
  _lock_try=$((_lock_try+1))
done
[ "$LOCK_HELD" = true ] && trap 'rm -rf "$PATCH_LOCK" 2>/dev/null' EXIT

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
[class*="userMessage_"] [class*="content_"][class*="collapsed_"]{max-height:${USER_MSG_MAX_H}px !important;}
[class*="sessionsButtonText_"]{white-space:normal !important;display:-webkit-box !important;-webkit-line-clamp:3 !important;-webkit-box-orient:vertical !important;overflow:hidden !important;}
[class*="sessionsButtonContent_"]{max-width:unset !important;}
[class*="sessionsButton_"]{max-width:unset !important;}
/* Cap code/copy blocks to a configurable width (default 50%) + soft-wrap: visual wrap only (copy stays one logical line per paragraph), no horizontal scroll, box doesn't span the full chat. Cap the <pre> but keep the WRAPPER full width, so hovering anywhere across the full row still reveals the copy button (the hover lives on the wrapper). Position the button at the block's right edge via calc(100% - width) so it tracks the cap instead of sitting at the window edge. padding-top reserves a strip so the button doesn't cover the first line. Border matches the user-message border ($BORDER_COLOR). Wrapper/button classes are hashed per build, so match by prefix. */
[class*="codeBlockWrapper_"] pre,.chat-markdown-part pre{white-space:pre-wrap !important;overflow-wrap:anywhere !important;overflow-x:visible !important;padding-top:36px !important;max-width:$CODE_BLOCK_MAX_WIDTH !important;}
[class*="codeBlockWrapper_"] code{white-space:pre-wrap !important;overflow-wrap:anywhere !important;}
[class*="codeBlockWrapper_"] [class*="copyButton_"]{right:calc(100% - $CODE_BLOCK_MAX_WIDTH + 20px) !important;border:2px solid $BORDER_COLOR !important;}
/* Question-panel minimize: when the AskUserQuestion panel (the in-flow .permissionRequestContainer, keyed by its stable data-focused-index attr) carries the cc-q-min class, hide the question body / answer buttons / Esc hint, leaving only the one-line header (title + ✕ + our − button). Collapsing it also lets the extension's ResizeObserver shrink the transcript spacer, so the answer floating behind becomes readable. Sub-parts are hashed per build, matched by class prefix. */
[data-focused-index].cc-q-min [class*="questionsContainer_"],[data-focused-index].cc-q-min [class*="buttonContainer_"],[data-focused-index].cc-q-min [class*="keyboardHints_"]{display:none !important;}
/* User-message "Collapse": hovering any multi-line user message reveals a "Collapse" button (styled and anchored like the native Show more - the button lives INSIDE the position:relative expandableContainer so both share the same bottom anchor). Click folds THAT message to a single clipped line via the cc-msg-min class on its userMessage box - per-message, like the native Show more/less; Alt+click applies to ALL prompts at once. React re-renders wipe DOM classes, so the fold state lives in a JS-side set keyed by a hash of the message text and the 300ms scan re-applies the class (see the JS block). While folded we hide the native gradient + Show more/less + attachments and disable the wrapper's click-to-expand. The fold rule doubles an attribute selector to reach specificity (0,4,0): with a single one it ties/loses to our own 175px collapsed rule above (0,3,0) - both !important - and collapsed messages then refuse to fold (the v1.18.0-dev bug). When the native Show more (collapsed) or Show less (expanded) occupies the corner, our button shifts left of it via :has(); otherwise it takes the corner. Sub-part classes are hashed per build, matched by prefix. */
.cc-msg-minbtn{display:none;position:absolute;bottom:0;right:0;margin:4px;padding:8px;border:none;border-radius:4px;cursor:pointer;font-size:.85em;align-items:center;color:var(--app-menu-background);background-color:var(--app-menu-foreground);opacity:.9;z-index:5;white-space:nowrap;}
.cc-msg-minbtn:hover{opacity:1;transform:scale(1.05);}
[class*="userMessage_"]:hover .cc-msg-minbtn{display:flex;}
[class*="userMessage_"]:has([class*="content_"][class*="collapsed_"]) .cc-msg-minbtn,[class*="userMessage_"]:has([class*="collapseButton_"]) .cc-msg-minbtn{right:88px;}
[class*="userMessage_"].cc-msg-min .cc-msg-minbtn{right:0 !important;padding:2px 8px;margin:1px 4px;}  /* folded box is one line (~20px); slim the button so it fits inside instead of bleeding over the border */
[class*="userMessage_"].cc-msg-min [class*="content_"][class*="content_"]{max-height:1.5em !important;overflow:hidden !important;}
[class*="userMessage_"].cc-msg-min [class*="truncationGradient_"],[class*="userMessage_"].cc-msg-min [class*="buttonContainer_"],[class*="userMessage_"].cc-msg-min [class*="userMessageAttachments_"]{display:none !important;}
[class*="userMessage_"].cc-msg-min [class*="contentWrapper_"]{pointer-events:none !important;}
/* Harness-injected notifications (task-notification etc.) are sent INTO the conversation as user-role messages, so the webview's user-message component (U8t) renders them with the FULL prompt chrome as if the user typed them: the border, the sticky-to-top header (stickyHeader is applied to any text message), and the Rewind/Fork action bar. The 300ms scan tags them cc-harness-msg by their leading XML tag; here we strip all that chrome so they read as passive system output, not as your prompt. (0,2,0) outranks the base border rule (0,1,0), both !important. */
[class*="userMessage_"].cc-harness-msg{border:none !important;opacity:0.75;}
/* Kill the sticky-to-top behaviour: stickyHeader lives on the ancestor message_ container, so reach it via :has() and pin it static. (0,3,0) + !important beats the native .message_.stickyHeader_ (0,2,0). */
[class*="message_"][class*="stickyHeader_"]:has(.cc-harness-msg){position:static !important;}
/* Hide the native Rewind/Fork action bar: inside the inner userMessageContainer_ it is the sibling rendered right before .userMessage_, so it is the only direct child that is NOT the userMessage box. (Attachments live INSIDE .userMessage_, so they are untouched.) */
[class*="userMessageContainer_"]:has(> [class*="userMessage_"].cc-harness-msg) > :not([class*="userMessage_"]){display:none !important;}
/* Native RTL quirk fix: Show less is an in-flow flex child (justify-content:flex-end), so in RTL prose flex-end resolves to the LEFT corner while the absolute Show more sits right - the two buttons end up at opposite corners. Forcing LTR on the button row pins both to the right. */
[class*="userMessage_"] [class*="buttonContainer_"]{direction:ltr !important;}
/* Settings-menu on/off switches (Thinking, Switch models on flag, Remote control): the native ON track is background:var(--app-accent-color), which resolves to --vscode-inputOption-activeBorder, and the built-in themes leave that token a near-black gray (#2a2b2c on Dark Modern) - DARKER than the OFF track (--app-input-border, #333536) - so ON and OFF render identically and the only tell is the 14px thumb offset. Paint the ON track with the theme button accent, and the thumb with its PAIRED foreground rather than a hardcoded white: every theme defines button-foreground as contrasting with button-background, so this survives a light or white button colour, where a fixed white thumb would vanish - the same theme-token assumption that caused the original bug. Track/thumb classes are hashed per build, so match by prefix; the thumb is a child of the track, so the second rule only touches switches that are ON. */
[class*="trackOn_"]{background:var(--vscode-button-background,#0078d4) !important;}
[class*="trackOn_"] [class*="thumb_"]{background:var(--vscode-button-foreground,#fff) !important;}
/* Per-message time stamp (the JS block below captures the times). The message block is align-items:flex-start, so the line needs its own full width before text-align can push it to the right edge. Latin digits stay LTR whatever the message language, and tabular numerals keep the line from jittering as the digits change. pointer-events:none so it can never swallow a click meant for the message. */
.cc-msg-time{width:100%;direction:ltr;text-align:right;font-size:10px;line-height:1.4;opacity:0.45;margin-top:2px;user-select:none;font-variant-numeric:tabular-nums;pointer-events:none;}
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

    # ── Align the collapse DECISION with the displayed height ──────────
    # The user-message expandable component receives maxHeight:60 (px) and uses
    # it BOTH as the inline display cap AND as the "is overflowing?" threshold
    # (scrollHeight > maxHeight -> collapsed class + fade gradient + Show more).
    # Our CSS only overrides the DISPLAY cap, so every message between 60px and
    # the CSS cap rendered fully yet still wore a pointless fade + Show more.
    # Patch the one call site (",maxHeight:60}" appears exactly once in the
    # bundle) to read our runtime global, with the conf value baked in as the
    # fallback for renders that happen before our appended block runs.
    # Idempotent: the patched text no longer contains ",maxHeight:60}". If a
    # future bundle changes the literal, the sed no-ops and behavior falls back
    # to the old display-only override (CSS) - degraded but never broken.
    sed -i 's@,maxHeight:60}@,maxHeight:window.__ccUserMsgMaxH||'"$USER_MSG_MAX_H"'}@' "$jstmp"

    # ── Copy Link -> absolute path ──────────────────────────────────────
    # The link context menu's "Copy Link" writes the RAW href to the clipboard.
    # For relative file links (the only kind that both renders and opens) that
    # is a workspace-relative path - useless outside VSCode (File Explorer,
    # terminal). Patch the one handler (unique shape in the bundle: a no-arg
    # function whose whole body is writeText(<id>),<id>() - verified single
    # match on 2.1.175) to route through window.__ccResolveHref (defined in the
    # appended block below), which expands relative hrefs against the session
    # cwd into an absolute backslash path. Identifiers are matched generically
    # so minifier renames don't break it; if the shape ever changes the sed
    # no-ops and Copy Link falls back to native (degraded, never broken).
    # Idempotent: the patched body starts writeText(window. which no longer
    # matches the <id>),<id>() shape.
    sed -i -E 's@function ([A-Za-z_$][A-Za-z0-9_$]*)\(\)\{navigator\.clipboard\.writeText\(([A-Za-z_$][A-Za-z0-9_$]*)\),([A-Za-z_$][A-Za-z0-9_$]*)\(\)\}@function \1(){navigator.clipboard.writeText(window.__ccResolveHref?window.__ccResolveHref(\2):\2),\3()}@' "$jstmp"

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
      /* 1M detection: Opus/Fable are always 1M; models with [1m] tag are 1M; usage >200K = 1M */
      var is1M=/opus|fable/i.test(currentModel)||/\[1m\]/i.test(currentModel)||raw>200000;
      var cap=is1M?1000000:200000;
      var pct=Math.round(raw*100/cap);
      var x=document.getElementById('claude-ui-context-badge');
      if(!x)return;
      x.textContent=fmtTokens(raw)+' / '+fmtCap(cap)+' ('+pct+'%)';
      var col=pct>=50?'#f14c4c':pct>=40?'#e8ab3a':pct>=30?'#e8d24f':'#3dc9b0';
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
    /* skip harness-injected notifications (cc-harness-msg, tagged by the collapse scan) - navigation is for the user's own prompts */
    var msgs=Array.from(document.querySelectorAll('[class*="message_"][class*="userMessageContainer_"]')).filter(function(m){return !m.querySelector('.cc-harness-msg');});
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
     sits under the border toggle); standalone in the context-badge popup.
     If the Hebrew RTL pack is installed it publishes its version to a window
     global (cross-pack handshake, read lazily here at click time) - append it
     so one right-click answers "what is running" for both packs. */
  function versionLineEl(withSep){
    var v=document.createElement('div');
    var vt='UI Extras v'+UI_VERSION;
    try{if(window.__ccRtlVersion)vt+=' | Hebrew RTL v'+window.__ccRtlVersion;}catch(e){}
    v.textContent=vt;
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
    var m=base.match(/(opus|sonnet|haiku|fable)-(\d+)(?:-(\d+))?/i), name;
    if(m){var fam=m[1].charAt(0).toUpperCase()+m[1].slice(1).toLowerCase();name=fam+' '+m[2]+(m[3]?'.'+m[3]:'');}
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
      var msgs=Array.from(document.querySelectorAll('[class*="message_"][class*="userMessageContainer_"]')).filter(function(m){return !m.querySelector('.cc-harness-msg');});
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

/* \u2500\u2500 Copy Link as absolute path \u2500\u2500
   The bundle's native link context menu copies the RAW href; a sed pass (see
   "Copy Link -> absolute path" in the hook) reroutes it through this resolver.
   Real URLs pass through untouched; file links are %-decoded, stripped of
   #L42 / :42 line suffixes, and resolved against the session cwd into a
   Windows backslash path ready for File Explorer / terminal pasting.
   cwd sources: launch_claude messages sniffed by the top-of-bundle shim
   (exact per-session cwd, covers worktrees), falling back to the workspace
   defaultCwd from get_claude_state_response. */
;(function(){
  window.__ccResolveHref=function(h){
    try{
      if(!h)return h;
      h=String(h);
      if(/^[A-Za-z][A-Za-z0-9+.-]+:\/\//.test(h)||/^mailto:/i.test(h))return h;
      var p=h.replace(/#.*$/,'');                  /* drop #L42 fragment */
      try{p=decodeURIComponent(p);}catch(_){}
      p=p.replace(/:L?\d+(-L?\d+)?$/,'');          /* drop :42 / :L42-L51 suffix */
      if(/^[A-Za-z]:[\\/]/.test(p))return p.replace(/\//g,'\\');
      var w=window.__ccCwd;
      if(!w)return h;                              /* no cwd known yet - native behavior */
      w=String(w).replace(/[\\/]+$/,'');
      p=p.replace(/^\.[\\/]/,'');
      while(/^\.\.[\\/]/.test(p)){w=w.replace(/[\\/][^\\/]*$/,'');p=p.slice(3);}
      return (w+'\\'+p).replace(/\//g,'\\');
    }catch(_){return h;}
  };
  /* fallback cwd: state.defaultCwd, which travels in exactly two messages
     (verified against extension.js 2.1.175):
       - init_response (response to the init request the webview sends on every
         boot AND on every reconnect-after-reload - the launch_claude sniff
         never fires on reconnects, so this is the reliable path)
       - update_state (pushed BY the extension as an incoming request, repeatedly)
     NOT in get_claude_state_response - that config only carries account info.
     The shim's launch_claude sniff (exact per-session cwd, covers worktrees),
     when it fires, takes precedence. */
  window.addEventListener('message',function(e){
    var d=e.data;
    if(!d||d.type!=='from-extension')return;
    var m=d.message;
    if(!m)return;
    var st=(m.response&&m.response.type==='init_response'&&m.response.state)||
           (m.request&&m.request.type==='update_state'&&m.request.state);
    var c=st&&st.defaultCwd;
    if(c&&!window.__ccCwdFromLaunch)window.__ccCwd=c;
  });
})();

/* ── Binary file links open in the OS default app ──
   Every in-chat file link is sent to the extension as an `open_file` request,
   which it implements with window.showTextDocument - i.e. it ASKS for the text
   editor. That bypasses any custom editor registered for the extension (the
   installed PDF preview included), so a PDF/image/zip renders as raw bytes.
   Web links travel a different request, `open_url`, which ends in
   env.openExternal and hands the target to the OS.
   So: catch clicks on links whose resolved target is a binary file and re-send
   them as `open_url` with a file:/// URI. Capture phase + stopImmediatePropagation
   so the app's own onClick never runs. Every guard falls through to native
   behavior (no api / no channel / unresolvable path), so the worst case is
   exactly today's behavior, never a dead link.
   Reuses __ccResolveHref from the Copy Link block above (relative href +
   session cwd -> absolute Windows path, #L42 / :42 suffixes stripped). */
;(function(){
  var BIN=/\.(pdf|docx?|xlsx?|pptx?|odt|ods|rtf|zip|rar|7z|tar|gz|png|jpe?g|gif|webp|bmp|tiff?|ico|psd|ai|mp[34]|m4a|wav|flac|mov|avi|mkv|webm|exe|msi)$/i;
  document.addEventListener('click',function(e){
    try{
      if(e.button!==0||e.ctrlKey||e.metaKey||e.altKey||e.shiftKey)return;
      var t=e.target;
      var a=(t&&t.closest)?t.closest('a[href]'):null;
      if(!a)return;
      var h=a.getAttribute('href')||'';
      if(!h)return;
      /* real URLs (http, mailto, vscode, ...) keep native behavior */
      if(/^[A-Za-z][A-Za-z0-9+.-]*:/.test(h)&&!/^file:/i.test(h))return;
      var p=window.__ccResolveHref?window.__ccResolveHref(h):h;   /* -> C:\... */
      if(!/^[A-Za-z]:[\\/]/.test(p))return;                       /* unresolved - let the app handle it */
      if(!BIN.test(p))return;                                     /* text file - the editor is the right place */
      var api=window.__ccVscodeApi, ch=window.__ccChannelId;
      if(!api||ch==null)return;
      var url='file:///'+encodeURI(p.replace(/\\/g,'/')).replace(/#/g,'%23').replace(/\?/g,'%3F');
      e.preventDefault(); e.stopPropagation();
      if(e.stopImmediatePropagation)e.stopImmediatePropagation();
      api.postMessage({type:'request',channelId:ch,requestId:Math.random().toString(36).slice(2),
                       request:{type:'open_url',url:url}});
    }catch(_){}
  },true);
})();

/* ── Minimize button for the AskUserQuestion panel ──
   Anthropic floats the question panel over the transcript (z-index 20, 680px
   centered, up to 70vh tall), so when Claude answers AND asks in the same turn
   the panel covers the answer, and the only escape today is Esc (which discards
   the question). This injects a − button next to the panel's ✕ that collapses it
   to its one-line header (which, since the input area is a bottom-anchored flex
   column, parks on top of the prompt box); the glyph flips to ⬜ to restore.
   Scoped strictly to the AskUserQuestion panel via the presence of radio/checkbox
   options + the stable data-focused-index attr + the aria-label="Close" anchor. */
;(function(){
  if('__QUESTION_MINIMIZE__'!=='true')return;
  var MIN='cc-q-min';
  /* Swap the cloned button's icon to a minus (collapse) or square (restore),
     matching the ✕ in size AND weight. The native ✕ is a fill-based Heroicons
     glyph (viewBox 0 0 20 20): its strokes span ~5.2→14.8 (≈9.6 wide, centered)
     at ~1.5 thickness. We derive our shapes from that geometry, scaled to the
     cloned <svg>'s actual viewBox so it stays right if the icon size changes.
     fill/stroke are set EXPLICITLY (an inherited <line> would be invisible and an
     inherited <rect> solid, since the source icon is fill-based). Falls back to a
     text glyph if there's no svg to clone. */
  function setIcon(btn,restore){
    var svg=btn.querySelector('svg');
    if(svg){
      var vb=(svg.getAttribute('viewBox')||'0 0 20 20').split(/\s+/);
      var S=parseFloat(vb[2])||20, c=S/2, w=S*0.075, e=S*0.24;      /* center, stroke weight, half-extent */
      var n=function(x){return Math.round(x*100)/100;};
      svg.innerHTML=restore
        ? '<rect x="'+n(c-e)+'" y="'+n(c-e)+'" width="'+n(2*e)+'" height="'+n(2*e)+'" rx="'+n(w)+'" fill="none" stroke="currentColor" stroke-width="'+n(w)+'"/>'  /* □ restore */
        : '<rect x="'+n(c-e)+'" y="'+n(c-w/2)+'" width="'+n(2*e)+'" height="'+n(w)+'" rx="'+n(w/2)+'" fill="currentColor" stroke="none"/>';                          /* − minimize */
    } else {
      btn.textContent=restore?'□':'−';
    }
  }
  /* Clone the native ✕ button so we inherit its exact iconButton classes and
     icon sizing, then replace only the glyph + wire our own toggle. cloneNode
     does NOT copy React's (delegated) onClick, so the clone won't also close. */
  function makeBtn(panel,closeBtn){
    var b=closeBtn.cloneNode(true);
    b.classList.add('cc-q-minbtn');          /* marker for dedupe; carries no style */
    setIcon(b,false);
    b.setAttribute('aria-label','Minimize');
    b.setAttribute('title','Minimize - read the answer behind this box');
    b.addEventListener('mousedown',function(e){e.preventDefault();});  /* don't steal focus */
    b.addEventListener('click',function(e){
      e.preventDefault(); e.stopPropagation();
      var min=panel.classList.toggle(MIN);
      setIcon(b,min);
      b.setAttribute('aria-label',min?'Restore':'Minimize');
      b.setAttribute('title',min?'Restore the question':'Minimize - read the answer behind this box');
    });
    return b;
  }
  function scan(){
    var panels=document.querySelectorAll('[data-focused-index]');
    for(var i=0;i<panels.length;i++){
      var p=panels[i];
      if(p.querySelector('.cc-q-minbtn'))continue;
      if(!p.querySelector('[role="radio"],[role="checkbox"]'))continue; /* AskUserQuestion only */
      var x=p.querySelector('[aria-label="Close"]');
      if(!x||!x.parentNode)continue;
      x.parentNode.insertBefore(makeBtn(p,x),x);
    }
  }
  setInterval(scan,300);
})();

/* ── "Collapse / Expand" button on user messages ──
   Hovering any multi-line user message reveals a "Collapse" button at its
   bottom-right (sliding left of the native Show more / Show less when one is
   there). Click folds THAT message to one line via the cc-msg-min class on its
   userMessage box - per-message, like the native Show more/less; Alt+click
   applies to ALL prompts at once. React re-renders wipe DOM classes, so the
   fold state lives in a JS-side set keyed by a hash of the message text, and
   the 300ms scan re-applies it after every re-render (two identical prompts
   share fate - acceptable). The button is skipped on single-line prompts
   (nothing to fold), measured against the content's computed line-height.
   The same scan also tags harness-injected notifications (task-notification
   & co, sent into the conversation as user-role messages) with cc-harness-msg
   so the CSS can un-border them - that tagging runs even when the collapse
   button is conf'd off.
   Also publishes the conf'd collapse threshold for the bundle-body maxHeight
   patch (window.__ccUserMsgMaxH) - keep this OUTSIDE the flag gate so disabling
   the button never un-fixes the collapse-decision alignment. */
;(function(){
  window.__ccUserMsgMaxH=parseInt('__USER_MSG_MAX_H__',10)||175;
  var BTN_ON='__USER_MSG_MINIMIZE__'==='true';
  var MIN='cc-msg-min';
  var HARNESS=/^\s*<(task-notification|system-reminder|local-command-stdout|command-name|command-message)\b/;
  var folded={};   /* text-hash -> true; survives re-renders, resets on reload */
  /* Holding Alt switches the action to ALL prompts; the visible label says so
     live ("Collapse" <-> "Collapse all") while the key is down. Window blur
     (Alt+Tab) resets the flag, since the keyup never reaches us. */
  var altDown=false;
  function labelBtn(b,on){
    b.textContent=(on?'Expand':'Collapse')+(altDown?' all':'');
    b.title=altDown?(on?'Expand ALL prompts back':'Fold ALL prompts to one line')
                   :(on?'Expand this prompt back (hold Alt: all)':'Fold this prompt to one line (hold Alt: all)');
  }
  function refreshLabels(){
    var bs=document.querySelectorAll('.cc-msg-minbtn');
    for(var i=0;i<bs.length;i++){
      var box=bs[i].closest('[class*="userMessage_"]');
      labelBtn(bs[i],!!(box&&box.classList.contains(MIN)));
    }
  }
  function syncAlt(a){if(a!==altDown){altDown=a;refreshLabels();}}
  /* preventDefault on the bare Alt: on Windows VSCode moves keyboard focus to
     the menu bar on an Alt press, after which keydown/keyup never reach this
     webview again (the "Alt works only once" bug). */
  window.addEventListener('keydown',function(e){if(e.key==='Alt'){e.preventDefault();syncAlt(true);}});
  window.addEventListener('keyup',function(e){if(e.key==='Alt'){e.preventDefault();syncAlt(false);}});
  window.addEventListener('blur',function(){syncAlt(false);});
  /* Keyboard focus can still leave the webview - but mouse events keep flowing
     regardless of keyboard focus and carry the live modifier state, and the
     label only matters under hover anyway. Any mouse movement re-syncs. */
  document.addEventListener('mousemove',function(e){syncAlt(e.altKey);},true);
  function contentOf(box){return box.querySelector('[class*="content_"]');}
  function keyOf(c){var s=c.textContent||'',h=5381,i=s.length;while(i)h=((h*33)^s.charCodeAt(--i))>>>0;return h+'_'+s.length;}
  function isOneLine(c){
    var lh=parseFloat(getComputedStyle(c).lineHeight);
    if(!lh||isNaN(lh))lh=20;
    return c.scrollHeight<lh*1.6;   /* scrollHeight ignores max-height clipping, so this stays correct while folded */
  }
  function setFold(k,on){ if(on)folded[k]=true; else delete folded[k]; }
  function makeBtn(box){
    var b=document.createElement('button');
    b.className='cc-msg-minbtn';
    b.type='button';
    b.addEventListener('mousedown',function(e){e.preventDefault();});  /* don't steal focus */
    b.addEventListener('click',function(e){
      e.preventDefault();e.stopPropagation();
      var c=contentOf(box); if(!c)return;
      var on=!folded[keyOf(c)];
      if(e.altKey){
        var all=document.querySelectorAll('[class*="userMessage_"]');
        for(var i=0;i<all.length;i++){var cc=contentOf(all[i]);if(cc&&!isOneLine(cc))setFold(keyOf(cc),on);}
      } else {
        setFold(keyOf(c),on);
      }
      scan();
    });
    return b;
  }
  function scan(){
    var boxes=document.querySelectorAll('[class*="userMessage_"]');
    for(var i=0;i<boxes.length;i++){
      var box=boxes[i];
      var cont=box.querySelector('[class*="expandableContainer_"]');
      var c=contentOf(box);
      if(!cont||!c)continue;
      var isHarness=HARNESS.test(c.textContent||'');
      box.classList.toggle('cc-harness-msg',isHarness);
      /* Never dress a harness notification with OUR collapse button - it is not
         the user's prompt. Strip any leftover button/fold state and skip it. */
      if(isHarness){var stale=box.querySelector('.cc-msg-minbtn');if(stale)stale.remove();box.classList.remove(MIN);continue;}
      if(!BTN_ON)continue;
      var on=!!folded[keyOf(c)];
      box.classList.toggle(MIN,on);
      var have=box.querySelector('.cc-msg-minbtn');
      if(!on&&isOneLine(c)){if(have)have.remove();continue;}
      if(!have){have=makeBtn(box);cont.appendChild(have);}
      labelBtn(have,on);
    }
  }
  setInterval(scan,300);
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
  var LOG; try{ LOG=__UI_CHANGELOG__; }catch(e){ LOG=null; }   /* last 3 MAJOR versions */
  if(!LOG||!LOG.length)LOG=[{v:VER,n:''}];
  /* Pop only when there is a NEW MAJOR entry since the user last dismissed.
     LOG[0].v is the latest MAJOR version; a MAJOR=0 bump (maintenance/cosmetic)
     leaves LOG[0] unchanged, so the banner stays silent on those releases. */
  var TOP=LOG[0].v;
  /* Gate on "seen >= TOP", not exact match - exact match re-pops when a
     transiently-deployed higher version was dismissed and TOP then went
     back down (seen=1.17.0 vs TOP=1.15.0, observed live 2026-06-10). */
  function vge(a,b){a=String(a).split('.');b=String(b).split('.');for(var i=0;i<3;i++){var x=+a[i]||0,y=+b[i]||0;if(x!==y)return x>y;}return true;}
  function dismissed(){try{var s=localStorage.getItem(KEY);return !!(s&&vge(s,TOP));}catch(e){return false;}}
  if(dismissed())return;
  var ID='claude-ui-update-banner';
  var RTL_ID='claude-rtl-update-banner';   /* the Hebrew RTL pack's banner - anchor below it when both show */
  /* Persist the dismissal with retries: localStorage writes are flushed to disk
     asynchronously (Chromium batches ~5s), and VSCode recycles the webview
     several times while a fresh window settles - a write made just before a
     recycle is LOST, which is how a dismissed banner kept re-popping (observed
     live 2026-06-11). Re-writing the same value every 3s for ~45s makes one of
     the writes land after the churn. */
  function persistSeen(){
    try{localStorage.setItem(KEY,TOP);}catch(e){}
    var k=0,t=setInterval(function(){try{localStorage.setItem(KEY,TOP);}catch(e){}if(++k>=15)clearInterval(t);},3000);
  }
  function mount(){
    if(document.getElementById(ID)||!document.body)return;
    if(dismissed())return 'stop';   /* re-read at mount time: a dismissal persisted by an earlier webview incarnation (or another window) wins */
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
    x.addEventListener('click',function(){persistSeen();bar.remove();});
    bar.appendChild(icon);bar.appendChild(txt);bar.appendChild(x);
    document.body.appendChild(bar);
    /* Keep anchored below the RTL pack's banner while both are visible (the RTL
       one offsets below OURS only if it mounts later - cover both orders). */
    var anchor=setInterval(function(){
      if(!bar.isConnected){clearInterval(anchor);return;}
      var r=document.getElementById(RTL_ID);
      var h=r?r.getBoundingClientRect():null;
      bar.style.top=(h&&h.height>0)?Math.round(h.bottom)+'px':'0px';
    },800);
    /* If this version is dismissed in another window/webview sharing the same
       storage, hide here too instead of waiting for a reload. */
    window.addEventListener('storage',function(ev){
      if(ev.key===KEY&&dismissed()&&bar.isConnected)bar.remove();
    });
  }
  /* Delay the first mount ~10s: while a fresh VSCode window settles, the
     extension disposes and recreates the webview several times; banners shown
     during that churn are the ones whose dismissal gets lost. Short-lived
     incarnations now never show the banner at all, and the surviving one
     re-reads the gate right before mounting. */
  setTimeout(function(){
    if(mount()==='stop')return;
    var n=0,iv=setInterval(function(){if(mount()==='stop'||++n>50||document.getElementById(ID))clearInterval(iv);},200);
  },10000);
})();

/* ── Per-message time stamp ──
   A small dim clock under every block, like any chat app: the moment a prompt
   was sent, and the moment Claude finished answering. Times live in memory
   only - same contract as the collapse state above: they survive the React
   re-renders you hit while scrolling, and reset on reload. Nothing is stored,
   so there is nothing to grow or clean up. Gated by show_message_time. */
;(function(){
  if('__SHOW_MESSAGE_TIME__'!=='true')return;
  try{
    if(window.__ccMsgTimeInstalled)return;
    window.__ccMsgTimeInstalled=true;

    var CLS='cc-msg-time';
    var times={};        /* key -> ms   (survives re-renders, resets on reload) */
    var historical={};   /* keys that were already on screen when we started */
    var ready=false;

    function pad(n){return n<10?'0'+n:''+n;}
    function fmt(ms){var d=new Date(ms);return pad(d.getHours())+':'+pad(d.getMinutes())+':'+pad(d.getSeconds());}
    /* Message blocks are NOT direct children of the container - the app wraps
       each exchange in a turn_ element (messagesContainer_ > turn_ > message_),
       and that layer could change again. So: match by descent, drop anything
       nested inside another message block, and fall back to a document-wide
       query if the container class is ever renamed. Note the lowercase m in
       message_ - it deliberately misses userMessage_, errorMessage_,
       slashCommandMessage_ and friends, which all capitalise it. */
    function blocks(){
      var all=document.querySelectorAll('[class*="messagesContainer_"] [class*="message_"]');
      if(!all.length)all=document.querySelectorAll('[class*="message_"]');
      var out=[];
      for(var i=0;i<all.length;i++){
        var el=all[i],p=el.parentElement;
        if(p&&p.closest&&p.closest('[class*="message_"]'))continue;   /* nested block */
        out.push(el);
      }
      return out;
    }
    function isUser(el){return !!el.querySelector('[class*="userMessage_"]');}

    /* Same cheap djb2 the collapse block uses - no node cloning. Our own stamp
       line is skipped, otherwise appending it would change the hash and the
       key would drift on every pass. */
    function hashOf(el){
      var s='',k=el.childNodes;
      for(var j=0;j<k.length;j++){
        var c=k[j];
        if(c.nodeType===1&&String(c.className||'').indexOf(CLS)!==-1)continue;
        s+=c.textContent||'';
      }
      var h=5381,i=s.length;while(i)h=((h*33)^s.charCodeAt(--i))>>>0;
      return h+'_'+s.length;
    }
    function keyOf(el,i){return i+'_'+hashOf(el);}

    function stamp(el,ms){
      var line=null,k=el.childNodes;
      for(var j=0;j<k.length;j++){if(k[j].nodeType===1&&String(k[j].className||'').indexOf(CLS)!==-1){line=k[j];break;}}
      if(!line){line=document.createElement('div');line.className=CLS;el.appendChild(line);}
      var t=fmt(ms);
      if(line.textContent!==t)line.textContent=t;
    }

    /* Blocks already on screen at startup are history (reload, or switching
       back into an older session). There is no way to know when they actually
       happened, so leave them blank rather than stamp them with "now". */
    setTimeout(function(){
      var list=blocks();
      for(var i=0;i<list.length;i++)historical[keyOf(list[i],i)]=true;
      ready=true;
    },1500);

    function scan(){
      var list=blocks();
      for(var i=0;i<list.length;i++){
        var el=list[i],k=keyOf(el,i);
        /* A prompt is final the moment it appears, so it is stamped here. An
           answer is still streaming - its time is set by the result handler
           below, once the turn is actually over. */
        if(times[k]===undefined&&ready&&!historical[k]&&isUser(el))times[k]=Date.now();
        if(times[k]!==undefined)stamp(el,times[k]);
      }
    }

    /* result io_message = the turn is over (same event the cost badge uses).
       The last block is whatever Claude just finished with, so that is the one
       that gets the finish time. */
    window.addEventListener('message',function(e){
      try{
        var d=e.data;
        if(!d||d.type!=='from-extension')return;
        var msg=d.message;
        if(!msg||msg.type!=='io_message')return;
        var m=msg.message;
        if(!m||m.type!=='result')return;
        var list=blocks();
        if(!list.length)return;
        var i=list.length-1,el=list[i];
        if(isUser(el))return;          /* nothing was actually answered */
        times[keyOf(el,i)]=Date.now();
        scan();
      }catch(_){}
    });

    setInterval(scan,300);
    scan();
  }catch(err){ /* never break the bundle */ }
})();
JSPATCH

    cat >> "$jstmp" << 'JSEND'
/* Claude UI Extras JS End */
JSEND

    # Substitute border color placeholder
    sed -i "s|__BORDER_COLOR__|$BORDER_COLOR|g" "$jstmp"
    sed -i "s|__SHOW_CONTEXT_WINDOW__|$SHOW_CONTEXT_WINDOW|g" "$jstmp"
    sed -i "s|__RATE_LIMIT_DIAG__|$RATE_LIMIT_DIAG|g" "$jstmp"
    sed -i "s|__QUESTION_MINIMIZE__|$QUESTION_MINIMIZE|g" "$jstmp"
    sed -i "s|__USER_MSG_MAX_H__|$USER_MSG_MAX_H|g" "$jstmp"
    sed -i "s|__USER_MSG_MINIMIZE__|$USER_MSG_MINIMIZE|g" "$jstmp"
    sed -i "s|__SHOW_MESSAGE_TIME__|$SHOW_MESSAGE_TIME|g" "$jstmp"
    sed -i "s|__UI_SIG__|$UI_MARKER|g" "$jstmp"
    sed -i "s|__UI_VERSION__|$VERSION|g" "$jstmp"
    # The changelog JS array (built up top; apostrophes already U+2019-swapped,
    # no  " \ | &  in notes, so it's safe as a sed replacement string).
    sed -i "s|__UI_CHANGELOG__|$CHANGELOG_JS|g" "$jstmp"

    # Prepend the vscode-api capture shim to the very TOP of the bundle so it runs
    # before the app's one-shot acquireVsCodeApi() call. It wraps that call to stash
    # the api handle (window.__ccVscodeApi) and sniffs outgoing requests for the live
    # channelId (window.__ccChannelId, needed to fire get_context_usage from the
    # context-breakdown popup) and for the session cwd off launch_claude
    # (window.__ccCwd, used by the Copy Link absolute-path resolver).
    # No placeholders, so no sed pass needed.
    shimtmp="$js.uiextras.shim.$$"
    cat > "$shimtmp" << 'JSSHIM'
/* Claude UI Extras Shim Start */
;(function(){try{if(window.__ccShimInstalled)return;window.__ccShimInstalled=true;var orig=window.acquireVsCodeApi;if(typeof orig==='function'){window.acquireVsCodeApi=function(){var api=orig.apply(this,arguments);try{window.__ccVscodeApi=api;if(api&&api.postMessage&&!api.__ccPmWrapped){var op=api.postMessage.bind(api);api.postMessage=function(m){try{if(m&&m.type==='launch_claude'&&m.cwd){window.__ccCwd=m.cwd;window.__ccCwdFromLaunch=true;}}catch(_){}return op.apply(null,arguments);};api.__ccPmWrapped=true;}}catch(_){}return api;};}window.addEventListener('message',function(e){try{var d=e.data;if(!d)return;var m=(d.type==='from-extension')?d.message:d;if(m&&m.type==='io_message'&&m.channelId!=null)window.__ccChannelId=m.channelId;}catch(_){}},false);}catch(_){}})();
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


# Patching is done - hand the lock straight to the sibling pack instead of
# holding it through the auto-update section further down.
if [ "$LOCK_HELD" = true ]; then rm -rf "$PATCH_LOCK" 2>/dev/null; trap - EXIT; LOCK_HELD=false; fi
if [ "$FOUND" = false ]; then
  echo "Claude Code extension not found."
  exit 1
fi

# ── Remove obsolete bypass-claude-dir.js hook (retired v1.13.0) ───────────
# The .claude/ permission-prompt bug this worked around (anthropics/claude-code#39523)
# was fixed upstream. Verified 2026-06-04 against extension 2.1.162: with the hook
# fully disabled and the session in bypassPermissions mode, a write into
# .claude/commands/ produced no prompt. The hardcoded guard was narrowed to just
# .claude/commands + .claude/agents (+ .git/hooks/config) and no longer prompts in
# bypass mode, so the hook is dead weight. Delete the stale deployed copy if present.
BYPASS_HOOK_PATH="$HOME/.claude/scripts/bypass-claude-dir.js"
rm -f "$BYPASS_HOOK_PATH" 2>/dev/null

# ── Register hooks in ~/.claude/settings.json ────────────────────────────
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
// A read that fails for an instant used to fall through to s={} and then
// rewrite this file from scratch, taking every other hook, the model and the
// permission rules with it. Claude Code writes the same file (model,
// effortLevel, the settings-menu toggles) without an atomic swap, and the
// sibling pack writes it too, so a torn read is a real event, not a theory.
// On a failed read we skip registration for this session - it runs again on
// the next one anyway.
if (fs.existsSync(p)) {
  try { s = JSON.parse(fs.readFileSync(p,'utf8')); }
  catch(e) { console.log('settings.json could not be read just now - skipping hook registration rather than risk overwriting it'); process.exit(0); }
}
var before = JSON.stringify(s);
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

// PermissionRequest bypass hook RETIRED (v1.13.0) -- strip any stale registration.
// Upstream #39523 was fixed; the .claude/ guard no longer prompts in bypass mode.
// Kept in git history (tag <= v1.12.0) in case the bug ever regresses.
if (s.hooks.PermissionRequest) {
  s.hooks.PermissionRequest = s.hooks.PermissionRequest.filter(function(h){
    return !(h.hooks && h.hooks.some(function(hh){ return hh.command && hh.command.indexOf('bypass-claude-dir.js') !== -1; }));
  });
  if (s.hooks.PermissionRequest.length === 0) delete s.hooks.PermissionRequest;
}

// Only touch the file when something actually changed, and swap it in
// atomically so nobody can ever read a half-written settings.json from us.
// In steady state this writes nothing at all, which removes the race window
// instead of merely surviving it.
if (JSON.stringify(s) !== before) {
  var stmp = p + '.tmp' + process.pid;
  fs.writeFileSync(stmp, JSON.stringify(s, null, 2), 'utf8');
  fs.renameSync(stmp, p);
}
" 2>/dev/null || echo "Note: could not update hooks (node not found)"

# ── Auto-update (background, every session) ───────────────────────────────
# v1.20.0: the check no longer blocks session start and no longer waits 24h.
#
# Part 1 — version check, spawned as a DETACHED background job: session start
# never waits on the network (the old synchronous check cost up to ~3s offline,
# inside a BLOCKING SessionStart hook). Gated to once per 5 minutes only so
# rapid-fire new chats don't hammer GitHub. When the remote VERSION differs and
# the fetched script passes bash -n, the job swaps the script on disk (same-dir
# temp + atomic mv — never truncate a possibly-running script in place) and
# leaves a marker file. No exec — this session already ran the old injection.
#
# Part 2 — pending-update notice, on the FIRST session that runs the NEW
# script: the bundle on disk is freshly patched (signature changed), but the
# webview in memory may still run the old injection until the window reloads.
# The hook's stdout is NOT rendered to the user — it lands in Claude's context
# — so the notice is written as an instruction TO CLAUDE to tell the user to
# reload. Printed once; after the reload the in-webview changelog banner takes
# over. (The in-webview banner itself needs no reload line: by the time it
# shows, the new code is already live.)
#
# Fails open on any error. auto_update=false in ui.conf disables the check
# (a marker left by an earlier download is still announced — it already
# happened).
SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
NOTE_FILE="$SCRIPT_DIR/.ui-extras-update-pending"
if [ "$AUTO_UPDATE" = "true" ]; then
  STATE_FILE="$SCRIPT_DIR/.ui-extras-last-update-check"
  NOW=$(date +%s)
  LAST=0
  [ -f "$STATE_FILE" ] && LAST=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
  if [ $((NOW - LAST)) -gt 300 ]; then
    echo "$NOW" > "$STATE_FILE"
    (
      TMP="$(mktemp 2>/dev/null || echo "/tmp/inject-ui-$$.sh")"
      if curl -fsSL --connect-timeout 5 --max-time 30 -o "$TMP" "$REMOTE_URL" 2>/dev/null; then
        # VERSION in the file is an array deref ("${CHANGELOG_VERS[0]}"), so
        # grep it from the changelog array itself, not the assignment line.
        REMOTE_VER="$(grep -m1 '^CHANGELOG_VERS=' "$TMP" | sed 's/^CHANGELOG_VERS=( *"\([^"]*\)".*/\1/')"
        if [ -n "$REMOTE_VER" ] && [ "$REMOTE_VER" != "$VERSION" ] && bash -n "$TMP" 2>/dev/null; then
          cp "$TMP" "$SELF.new.$$" && mv -f "$SELF.new.$$" "$SELF" && echo "$REMOTE_VER" > "$NOTE_FILE"
        fi
      fi
      rm -f "$TMP" "$SELF.new.$$"
    ) </dev/null >/dev/null 2>&1 &
  fi
fi
if [ -f "$NOTE_FILE" ]; then
  PENDING_VER="$(head -1 "$NOTE_FILE" 2>/dev/null | tr -d '[:space:]')"
  rm -f "$NOTE_FILE"
  # Announce only if this process is actually the downloaded version (the swap
  # happened and the new script is the one running now); a stale/mismatched
  # marker is silently dropped.
  if [ "$PENDING_VER" = "$VERSION" ]; then
    echo ""
    echo "💡 חבילת שיפורי הממשק (UI Extras) עודכנה אוטומטית לגרסה $VERSION (נבדק מול הגרסה: $COMPATIBLE_EXT_VERSION)"
    echo "חדש: $UPDATE_NOTE"
    echo "IMPORTANT instruction to Claude: the Claude Code UI Extras pack was just auto-updated on disk, but the current window still runs the previous version. At the START of your reply, tell the user (in the conversation's language) that a UI Extras update to v$VERSION was installed, briefly what is new (translate the Hebrew note above if needed), and that to activate it they should reload the window: press Ctrl+Shift+P, then run the command: Developer: Reload Window."
  fi
fi
