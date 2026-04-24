<div dir="rtl">

# תוספות ממשק לקלוד קוד

שיפורים קטנים לחוויית השימוש בתוסף Claude Code ל-VSCode.
הפיצ'רים מסודרים מהחדש ביותר לישן (מי שחוזר לאחר תקופה יראה מיד מה חדש).

---

## פיצ'רים

### ‏🆕 חיווי Context Window

<p dir="rtl">‏Badge קטן בפינה הימנית של אזור הקלט שמציג <b>כמה מחלון הקונטקסט של השיחה הנוכחית נצרך כרגע</b>. לכל חלון VSCode חיווי משלו, בהתאם לשיחה שלו.</p>

<ul dir="rtl">
<li>פורמט: <code dir="ltr">349.4k / 1.0M (35%)</code> — טוקנים שנצרכו / תקרת המודל / אחוז</li>
<li>זיהוי אוטומטי של תקרה — 200K או 1M (מודל עם חלון מורחב), מבוסס על ה-usage בפועל</li>
<li>צבעים לפי שימוש: ירוק (&lt;50%), כתום (50-79%), אדום (≥80%)</li>
<li>ניתן לכבות/להדליק עם דגל <code>show_context_window</code> ב-<code>ui.conf</code> (ברירת מחדל: דולק)</li>
</ul>

<p align="right"><img src="screenshots/context-window.jpg" alt="context window badge" height="110"/></p>

### עקיפת חלוניות הרשאה ב-`.claude/` (bypass mode)

מגרסה v2.1.78, Claude Code מציגה חלונית אישור בכל כתיבה ל-`.claude/commands/`, `.claude/agents/`, ו-`.claude/skills/` — **גם כשהסשן במצב `bypassPermissions` מלא**. זה באג ידוע שמתועד ב-[META issue #39523](https://github.com/anthropics/claude-code/issues/39523), פתוח תשעה חודשים ולא פתור. שום הגדרה, allow rules, `--dangerously-skip-permissions` או wildcards לא פותרים את זה.

הפתרון: `PermissionRequest` hook קטן (`bypass-claude-dir.js`, כ-25 שורות Node) שמאשר אוטומטית פעולות Edit/Write/MultiEdit/NotebookEdit ו-Bash שנוגעות ב-`.claude` — **אבל רק כשהסשן כבר ב-`bypassPermissions`**. במצב Ask/Plan/acceptEdits ההוק שקט לחלוטין, והחלוניות הרגילות מופיעות כרגיל.

**מטריצת התנהגות:**

| מצב | כתיבה ל-`.claude/` | כתיבה רגילה | Bash על `.claude/` |
|---|---|---|---|
| `bypassPermissions` | שקט ✓ | שקט ✓ | שקט ✓ |
| `default` (Ask) | חלונית | חלונית | חלונית |
| `plan` | plan mode מכובד | plan mode מכובד | plan mode מכובד |
| `acceptEdits` | ללא השפעה | שקט ✓ | ללא השפעה |

**איך זה עובד:** ההוק קורא את ה-payload של קריאת הכלי מ-stdin, מזהה `.claude` בנתיב הקובץ או בפקודת Bash, בודק ש-`permission_mode === 'bypassPermissions'`, ומחזיר את הפורמט הנכון `hookSpecificOutput.decision.behavior: "allow"`. חשוב: פורמט שטוח `{"behavior":"allow"}` **לא עובד** ב-Claude Code v2.1.107 — הסכמה המקוננת היא המחייבת.

**מגבלה ידועה:** לתוסף Claude Code ל-VSCode יש [באג נפרד](https://github.com/anthropics/claude-code/issues/36348) — `defaultMode: "bypassPermissions"` ב-settings.json לא נתפס בפתיחת סשן, כל סשן חדש נפתח במצב `default` (Ask). עדיין צריך לחיצה ידנית אחת על `Shift+Tab` בפתיחה כדי להיכנס ל-bypass. מרגע זה והלאה, ההוק שומר על הסשן שקט.

### חיווי API + עלות סשן (עודכן)

במצב הרגיל (מנוי Claude.ai) אין שום חיווי — נקי ושקט.
החיווי מופיע **רק** באחד משני המצבים:

<ul dir="rtl">
<li><b>Extra</b> (אדום) — עברת את המכסה השעתית במנוי. מוצג <code dir="ltr">Extra $X.XXX</code> עם עלות חריגה מצטברת מרגע ה-overage</li>
<li><b>API</b> (כתום) — מחובר עם מפתח API. מוצג <code>API</code> + עלות מצטברת של הסשן <code dir="ltr">$X.XXX</code>, תמיד גלוי</li>
</ul>

הזיהוי מתבצע בזמן ריצה דרך המסר `get_claude_state_response` שהתוסף שולח לכל חלון בנפרד — כך שכל חלון VSCode מציג את המצב הנכון שלו.

</div>

<table>
<tr>
<td width="70%" align="center"><img src="screenshots/sub-extra.jpg" alt="Extra usage overage" width="100%"/></td>
<td width="30%" align="right" dir="rtl"><b>Extra</b> (אדום)<br>עברת את המכסה השעתית — עלות חריגה מצטברת מרגע ה-overage</td>
</tr>
<tr>
<td width="70%" align="center"><img src="screenshots/api-cost.jpg" alt="API with cost" width="100%"/></td>
<td width="30%" align="right" dir="rtl"><b>API</b> (כתום)<br>מפתח API — עלות מצטברת של הסשן, מוצג תמיד</td>
</tr>
</table>

<div dir="rtl">

### ניווט בין הודעות (↑ ↓ ⤓)
שלושה כפתורים שמוזרקים לאזור הקלט:

<ul dir="rtl">
<li><b>↑</b> — קפיצה להודעת המשתמש הקודמת</li>
<li><b>↓</b> — קפיצה להודעת המשתמש הבאה</li>
<li><b>⤓</b> — גלילה לתחתית השיחה (אחרי כל ההודעות, כולל התגובה האחרונה)</li>
</ul>

הניווט עוצר בהודעה הראשונה / האחרונה — ללא לולאה.
מדגיש את ההודעה שאליה קפצת עם אנימציית פולס קצרה.

<p align="right"><img src="screenshots/navigation arrows.jpg" alt="navigation arrows" height="80"/></p>

### מסגרת להודעות משתמש

מסגרת עדינה סביב ההודעות שלך, כדי שתוכל לסרוק את השיחה ולהבדיל בקלות בין הפרומפטים שלך לתשובות של קלוד.
ניתן להדליק/לכבות עם קליק ימני על כפתורי הניווט ↑↓⤓.
צבע ברירת המחדל ניתן לשינוי בקובץ `ui.conf`.

<p align="right"><img src="screenshots/border.jpg" alt="border around user message" height="300"/></p>

### הרחבת הודעות משתמש
קלוד קוד מכווץ הודעות ארוכות לכ-3 שורות עם כפתור "הצג עוד". הפיצ'ר הזה מגדיל את המגבלה לכ-7 שורות, כך שהודעות בינוניות נראות במלואן בלי שום לחיצה.

### היסטוריית שיחות (רב-שורתי)
קלוד קוד רגיל חותך את שמות השיחות בסיידבר לשורה אחת. הפיצ'ר הזה מאפשר לכל פריט להציג עד 3 שורות, כדי שתוכל לקרוא על מה דובר בשיחה.

<p align="right"><img src="screenshots/3 liner.jpg" alt="3 liner history" height="300"/></p>

### העתקה כ-Markdown
קליק ימני על טקסט מסומן בשיחה פותח תפריט עם שתי אפשרויות:

<ul dir="rtl">
<li><b>Copy</b><br>מעתיק עם עיצוב מלא, מתאים להדבקה ב-Word, Notion וכדומה</li>
<li><b>Copy as Markdown</b><br>ממיר את הטקסט ל-Markdown גולמי ומעתיק כטקסט רגיל</li>
</ul>

התפריט מופיע רק כשיש טקסט מסומן. בלי סימון — קליק ימני עובד כרגיל.

<p align="right"><img src="screenshots/copy as markdown.jpg" alt="copy as markdown" height="300"/></p>

---

## התקנה

### התקנה מהירה (הדבקה לתוך Claude Code)

העתיקו את הבלוק הבא והדביקו אותו לתוך Claude Code — הוא יעשה את השאר:

</div>

<div dir="ltr">

```
Install the Claude Code UI extras (UI enhancements + .claude/ bypass hook).
Do all these steps:

Step 1 — Create a scripts directory in the current working directory (if it doesn't exist).

Step 2 — Download the install script from the repo and save it to scripts/:
  curl -o scripts/inject-ui.sh https://raw.githubusercontent.com/arielmoatti/claude-code-ui-extras/main/inject-ui.sh

Step 3 — Run the script once (`bash scripts/inject-ui.sh`). This patches the webview, installs the bypass hook to ~/.claude/scripts/, and registers both SessionStart and PermissionRequest hooks in ~/.claude/settings.json.

Step 4 — Ask me to do Reload Window (Ctrl+Shift+P → Developer: Reload Window).

Step 5 — After the reload, remind me to press Shift+Tab once to enter bypassPermissions mode — otherwise the `.claude/` bypass hook has nothing to act on (Claude Code opens sessions in Ask mode by default due to a separate extension bug).
```

</div>

<div dir="rtl">

> **שימו לב:** הפרומפט באנגלית בכוונה — כי קלוד צריך להבין את ההוראות ולבצע אותן.

הסקריפט יבצע:

<ul dir="rtl">
<li>הזרקת שיפורי ה-UI לתוך ה-<code>webview</code> של קלוד קוד</li>
<li>רישום <code>SessionStart</code> hook כדי שההזרקה תבוצע אוטומטית אחרי כל עדכון של התוסף</li>
<li>התקנת <code>bypass-claude-dir.js</code> ל-<code>~/.claude/scripts/</code></li>
<li>רישום <code>PermissionRequest</code> hook לעקיפת חלוניות האישור על <code>.claude/</code> במצב bypass</li>
</ul>

### התקנה ידנית

<ol dir="rtl">
<li>הורידו את <code dir="ltr">inject-ui.sh</code> לתיקיית <code dir="ltr">scripts/</code> בפרויקט</li>
<li>הריצו <code dir="ltr">bash scripts/inject-ui.sh</code></li>
<li>עשו Reload Window ב-VSCode (<code dir="ltr">Ctrl+Shift+P → Developer: Reload Window</code>)</li>
<li>לחצו <code dir="ltr">Shift+Tab</code> בתחילת כל סשן חדש כדי להיכנס למצב bypassPermissions</li>
</ol>

---

## הגדרות

ערוך את `scripts/ui.conf` — שני פרמטרים נתמכים:

</div>

```
# צבע מסגרת הודעות משתמש (כל ערך CSS תקין)
border_color=rgba(249,131,131,0.5)

# הצגת badge של Context Window (true / false)
show_context_window=true
```

<div dir="rtl">

לאחר מכן הרץ מחדש את `bash scripts/inject-ui.sh` וטען מחדש את VSCode.

---

## הסרה

מחק את הבלוק המוזרק מתוך `webview/index.js` ו-`webview/index.css`
(חפש `/* Claude UI Extras Patch Start */`), ולאחר מכן הסר את הרשומה מ-`SessionStart` hook ב-`~/.claude/settings.json`.

להסרת ה-bypass hook: מחק את `~/.claude/scripts/bypass-claude-dir.js` והסר את הרשומה מ-`PermissionRequest` hook ב-`~/.claude/settings.json`.

</div>

---

<details>
<summary>English version</summary>

## Features

Ordered newest-first — when you come back after a while, the top of the list shows what's new.

### 🆕 Context Window indicator

A small badge in the right corner of the input area showing **how much of the current conversation's context window is in use**. Each VSCode window has its own badge, reflecting its own session.

- Format: `349.4k / 1.0M (35%)` — used tokens / model cap / percentage
- Auto-detects cap — 200K or 1M (extended-window model), based on live usage data
- Color thresholds: green (<50%), orange (50-79%), red (≥80%)
- Toggle via `show_context_window` flag in `ui.conf` (default: on)

<p><img src="screenshots/context-window.jpg" alt="context window badge" height="90"/></p>

### Bypass `.claude/` permission prompts

Since Claude Code v2.1.78, a hardcoded guard prompts for every Edit/Write into `.claude/commands/`, `.claude/agents/`, and `.claude/skills/` — **even when the session is in `bypassPermissions` mode**. This is a known open bug tracked in [META issue #39523](https://github.com/anthropics/claude-code/issues/39523), unresolved for 9+ months. Settings overrides, allow rules, `--dangerously-skip-permissions`, and wildcard rules all fail to work around it.

The fix: a small `PermissionRequest` hook (`bypass-claude-dir.js`, ~25 lines of Node) that auto-approves Edit/Write/MultiEdit/NotebookEdit and Bash operations touching `.claude` paths — **but only when the session is already in `bypassPermissions` mode**. In Ask/Plan/acceptEdits modes, the hook stays silent and normal dialogs appear untouched.

**Behavior matrix:**

| Mode | `.claude/` writes | Regular writes | Bash on `.claude/` |
|---|---|---|---|
| `bypassPermissions` | silent ✓ | silent ✓ | silent ✓ |
| `default` (Ask) | dialog | dialog | dialog |
| `plan` | plan mode respected | plan mode respected | plan mode respected |
| `acceptEdits` | unaffected | silent ✓ | unaffected |

**How it works:** the hook reads the tool call payload from stdin, matches on `.claude` in the file path or Bash command, checks `permission_mode === 'bypassPermissions'`, and returns the correctly-formatted `hookSpecificOutput.decision.behavior: "allow"` response. A flat `{"behavior":"allow"}` is silently ignored by Claude Code v2.1.107 — the nested schema is required.

**Known limitation:** the Claude Code VSCode extension also has [a separate bug](https://github.com/anthropics/claude-code/issues/36348) where `defaultMode: "bypassPermissions"` in `settings.json` is not honored on session start — each session opens in `default` (Ask) mode. You still need one manual `Shift+Tab` at session start to enter bypass. Once there, this hook keeps the rest of the session silent.

### API indicator + session cost (updated)

In regular mode (Claude.ai subscription) there's no indicator — clean and quiet.
The indicator appears **only** in one of two cases:

<table>
<tr>
<td width="30%"><b>Extra</b> (red) — exceeded hourly quota, shows overage cost since the moment it started</td>
<td width="70%" align="center"><img src="screenshots/sub-extra.jpg" alt="Extra usage overage" width="100%"/></td>
</tr>
<tr>
<td width="30%"><b>API</b> (orange) — connected via API key, cumulative session cost always visible</td>
<td width="70%" align="center"><img src="screenshots/api-cost.jpg" alt="API with cost" width="100%"/></td>
</tr>
</table>

Detection happens at runtime via `get_claude_state_response` — each VSCode window shows its own correct state.

### Message Navigation (↑ ↓ ⤓)
Three buttons injected into the input footer:
- **↑** — jump to previous user message
- **↓** — jump to next user message
- **⤓** — scroll to the absolute bottom of the conversation (past all messages, including the latest model response)
- Navigation stops at the first / last message — no looping
- Highlights the target message with a brief pulse animation

<p><img src="screenshots/navigation arrows.jpg" alt="navigation arrows" height="80"/></p>

### User Message Border
A subtle border around your messages, making it easy to visually separate your prompts from Claude's responses.
Toggle on/off with a right-click on the ↑↓⤓ navigation buttons.
Default color is configurable in `ui.conf`.

<p><img src="screenshots/border.jpg" alt="border around user message" height="300"/></p>

### User Message Expand
Claude Code collapses long user messages to ~3 lines with a "show more" button. This fix raises the limit to ~7 lines, so short-to-medium messages are fully visible without any interaction.

### Session History (multi-line)
The Claude Code sidebar normally truncates session names to a single line. This fix expands each entry to up to 3 lines, so you can actually read what a session was about.

<p><img src="screenshots/3 liner.jpg" alt="3 liner history" height="300"/></p>

### Copy as Markdown
Right-click on any selected text in the conversation to get a context menu with two options:
- **Copy** — copies the selection as rich text (preserves formatting when pasting into Word, Notion, etc.)
- **Copy as Markdown** — converts the selection to raw Markdown (`**bold**`, `# heading`, `` `code` ``, etc.) and copies it as plain text

This menu only appears when text is selected. When nothing is selected, right-click behaves normally.

<p><img src="screenshots/copy as markdown.jpg" alt="copy as markdown" height="300"/></p>

---

## Install

### Quick install (paste into Claude Code)

Copy and paste the following into your Claude Code chat — it will handle everything:

```
Install the Claude Code UI extras (UI enhancements + .claude/ bypass hook).
Do all these steps:

Step 1 — Create a scripts directory in the current working directory (if it doesn't exist).

Step 2 — Download the install script from the repo and save it to scripts/:
  curl -o scripts/inject-ui.sh https://raw.githubusercontent.com/arielmoatti/claude-code-ui-extras/main/inject-ui.sh

Step 3 — Run the script once (`bash scripts/inject-ui.sh`). This patches the webview, installs the bypass hook to ~/.claude/scripts/, and registers both SessionStart and PermissionRequest hooks in ~/.claude/settings.json.

Step 4 — Ask me to do Reload Window (Ctrl+Shift+P → Developer: Reload Window).

Step 5 — After the reload, remind me to press Shift+Tab once to enter bypassPermissions mode — otherwise the `.claude/` bypass hook has nothing to act on (Claude Code opens sessions in Ask mode by default due to a separate extension bug).
```

The script will:
- Inject the UI enhancements into Claude Code's webview
- Register a `SessionStart` hook so the injection is re-applied automatically after every Claude Code update
- Install `bypass-claude-dir.js` to `~/.claude/scripts/`
- Register a `PermissionRequest` hook that auto-approves `.claude/` operations when the session is in bypassPermissions mode

### Manual install

1. Download `inject-ui.sh` to your project's `scripts/` directory
2. Run `bash scripts/inject-ui.sh`
3. Reload VSCode window (`Ctrl+Shift+P → Developer: Reload Window`)
4. At the start of each new session, press `Shift+Tab` once to enter `bypassPermissions` mode

---

## Configuration

Edit `scripts/ui.conf` — two supported parameters:

```
# User message border color (any valid CSS color)
border_color=rgba(249,131,131,0.5)

# Show Context Window badge (true / false)
show_context_window=true
```

Then re-run `bash scripts/inject-ui.sh` and reload VSCode.

---

## Uninstall

Delete the injected block from Claude Code's `webview/index.js` and `webview/index.css`
(look for `/* Claude UI Extras Patch Start */`), then remove the `SessionStart` hook from `~/.claude/settings.json`.

To remove the bypass hook: delete `~/.claude/scripts/bypass-claude-dir.js` and remove the `PermissionRequest` hook entry from `~/.claude/settings.json`.

</details>
