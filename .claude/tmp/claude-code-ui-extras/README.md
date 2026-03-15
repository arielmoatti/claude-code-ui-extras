# Claude Code UI Extras

Quality-of-life UI enhancements for Claude Code (VSCode extension).
No RTL. No auto-approve. Just useful UI tweaks.

---

## Features

### User Message Border
A subtle border around your messages, making it easy to visually separate your prompts from Claude's responses.
Toggle on/off with a right-click on the ↑ or ↓ button.
Default color is configurable in `ui.conf`.

### Message Navigation (↑ ↓)
Two buttons injected into the input footer:
- **↑** — jump to previous user message
- **↓** — jump to next user message
- Stops at the first / last message (no looping)
- Highlights the target message with a brief pulse animation

### Scroll to Bottom (⤓)
A third button that scrolls the conversation to the absolute bottom — past all messages including the latest model response.
After clicking ⤓, the ↑↓ navigation resumes from the last user message.

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
