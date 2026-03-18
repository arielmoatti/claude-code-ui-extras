# Claude Code UI Extras

Quality-of-life UI enhancements for Claude Code (VSCode extension).

---

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
