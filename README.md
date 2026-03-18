<div dir="rtl">

# תוספות ממשק לקלוד קוד

שיפורים קטנים לחוויית השימוש בתוסף Claude Code לVSCode.

---

## פיצ'רים

### מסגרת להודעות משתמש
מסגרת עדינה סביב ההודעות שלך, כדי שתוכל לסרוק את השיחה ולהבדיל בקלות בין הפרומפטים שלך לתשובות של קלוד.
ניתן להדליק/לכבות עם קליק ימני על כפתורי הניווט ↑↓⤓.
צבע ברירת המחדל ניתן לשינוי בקובץ `ui.conf`.

### הרחבת הודעות משתמש
קלוד קוד מכווץ הודעות ארוכות לכ-3 שורות עם כפתור "הצג עוד". הפיצ'ר הזה מגדיל את המגבלה לכ-7 שורות, כך שהודעות בינוניות נראות במלואן בלי שום לחיצה.

### העתקה כ-Markdown
קליק ימני על טקסט מסומן בשיחה פותח תפריט עם שתי אפשרויות:
- **Copy** — מעתיק עם עיצוב מלא (מתאים להדבקה ב-Word, Notion וכו')
- **Copy as Markdown** — ממיר את הטקסט ל-Markdown גולמי (`**bold**`, `# כותרת`, `` `קוד` `` וכו') ומעתיק כטקסט רגיל

התפריט מופיע רק כשיש טקסט מסומן. בלי סימון — קליק ימני עובד כרגיל.

### היסטוריית שיחות (רב-שורתי)
קלוד קוד רגיל חותך את שמות השיחות בסיידבר לשורה אחת. הפיצ'ר הזה מאפשר לכל פריט להציג עד 3 שורות, כדי שתוכל לקרוא על מה דובר בשיחה.

### ניווט בין הודעות (↑ ↓ ⤓)
שלושה כפתורים שמוזרקים לאזור הקלט:
- **↑** — קפיצה להודעת המשתמש הקודמת
- **↓** — קפיצה להודעת המשתמש הבאה
- **⤓** — גלילה לתחתית השיחה (אחרי כל ההודעות, כולל התגובה האחרונה)
- הניווט עוצר בהודעה הראשונה / האחרונה — ללא לולאה
- מדגיש את ההודעה שאליה קפצת עם אנימציית פולס קצרה

---

## התקנה דרך קלוד קוד

העתק והדבק את הפקודה הבאה לצ'אט של קלוד קוד:

`Install the Claude Code UI extras (message border + navigation arrows).`

הפקודה המלאה עם כל השלבים נמצאת בגרסה האנגלית למטה.

---

הסקריפט יבצע:
- הזרקת השיפורים לתוך ה-webview של קלוד קוד
- רישום `SessionStart` hook כדי שההזרקה תתבצע אוטומטית אחרי כל עדכון של קלוד קוד

---

## הגדרות

ערוך את `scripts/ui.conf` כדי לשנות את צבע המסגרת:

</div>

```
border_color=rgba(249,131,131,0.5)
```

<div dir="rtl">

לאחר מכן הרץ מחדש את `bash scripts/inject-ui.sh` וטען מחדש את VSCode.

---

## הסרה

מחק את הבלוק המוזרק מתוך `webview/index.js` ו-`webview/index.css`
(חפש `/* Claude UI Extras Patch Start */`), ולאחר מכן הסר את הרשומה מ-`SessionStart` hook ב-`~/.claude/settings.json`.

</div>

---

<details>
<summary>English version</summary>

## Features

### User Message Border
A subtle border around your messages, making it easy to visually separate your prompts from Claude's responses.
Toggle on/off with a right-click on the ↑↓⤓ navigation button.
Default color is configurable in `ui.conf`.

### User Message Expand
Claude Code collapses long user messages to ~3 lines with a "show more" button. This fix raises the limit to ~7 lines, so short-to-medium messages are fully visible without any interaction.

### Copy as Markdown
Right-click on any selected text in the conversation to get a context menu with two options:
- **Copy** — copies the selection as rich text (preserves formatting when pasting into Word, Notion, etc.)
- **Copy as Markdown** — converts the selection to raw Markdown (`**bold**`, `# heading`, `` `code` ``, etc.) and copies it as plain text

This menu only appears when text is selected. When nothing is selected, right-click behaves normally.

### Session History (multi-line)
The Claude Code sidebar normally truncates session names to a single line. This fix expands each entry to up to 3 lines, so you can actually read what a session was about.

### Message Navigation (↑ ↓ ⤓)
Three buttons injected into the input footer:
- **↑** — jump to previous user message
- **↓** — jump to next user message
- **⤓** — scroll to the absolute bottom of the conversation (past all messages, including the latest model response)
- Navigation stops at the first / last message — no looping
- Highlights the target message with a brief pulse animation

---

## Install via Claude Code

Copy and paste the following into your Claude Code chat:

---

```
Install the Claude Code UI extras (message border + navigation arrows).
Do all these steps:

Step 1 — Create a scripts directory in the current working directory (if it doesn't exist).

Step 2 — Download the script from the repo and save it to scripts/:
  curl -o scripts/inject-ui.sh https://raw.githubusercontent.com/arielmoatti/claude-code-ui-extras/main/inject-ui.sh

Step 3 — Run the script once to apply the fix.

Step 4 — Ask me to do Reload Window (Ctrl+Shift+P → Developer: Reload Window).
```

---

The script will:
- Inject the UI enhancements into Claude Code's webview
- Register a `SessionStart` hook so the injection is re-applied automatically after every Claude Code update

---

## Configuration

Edit `scripts/ui.conf` to change the border color:

```
border_color=rgba(249,131,131,0.5)
```

Then re-run `bash scripts/inject-ui.sh` and reload VSCode.

---

## Uninstall

Delete the injected block from Claude Code's `webview/index.js` and `webview/index.css`
(look for `/* Claude UI Extras Patch Start */`), then remove the `SessionStart` hook from `~/.claude/settings.json`.

</details>
