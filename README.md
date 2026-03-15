# Claude Code UI Extras

Small quality-of-life enhancements for the Claude Code VS Code extension.
No RTL, no auto-approve — just UI polish.

## Features

- **User message border** — a subtle colored border around your messages, so you can visually scan the conversation at a glance. Toggle on/off at any time.
- **Message navigation (↑↓)** — two buttons injected into the prompt footer that jump between your messages in the conversation, with a pulse highlight on landing.

## Install via Claude Code

> Copy everything between the lines and paste it into Claude Code:

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

## Manual install

```bash
git clone https://github.com/arielmoatti/claude-code-ui-extras.git
cd claude-code-ui-extras
bash inject-ui.sh
```

Reload VS Code after running.

## Customize border color

Edit `scripts/ui.conf` (or download it alongside the script):

```
border_color=rgba(249,131,131,0.5)
```

Accepts any valid CSS color — hex, rgb, rgba, hsl.
Re-run the script after changing, then reload VS Code.

## Usage

| Action | Result |
|--------|--------|
| Click ↑ / ↓ | Jump to previous / next user message |
| Right-click ↑ or ↓ | Toggle the message border on/off |

## After Claude Code updates

The script registers itself as a SessionStart hook — it re-runs automatically on every new session and re-injects if Claude Code was updated.
