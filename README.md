# Claude Code UI Extras

Small quality-of-life enhancements for the Claude Code VS Code extension.
No RTL, no auto-approve — just UI polish.

## Features

- **User message border** — a subtle colored border around your messages, so you can visually scan the conversation at a glance. Toggle on/off at any time.
- **Message navigation (↑↓)** — two buttons injected into the prompt footer that jump between your messages in the conversation, with a pulse highlight on landing.

## Install via Claude Code

> Copy everything between the lines and paste it into Claude Code:

---

Download and run the UI extras injection script:

```
mkdir -p scripts
curl -o scripts/inject-ui.sh https://raw.githubusercontent.com/arielmoatti/claude-code-ui-extras/main/inject-ui.sh
bash scripts/inject-ui.sh
```

Then reload VS Code: `Ctrl+Shift+P` → **Developer: Reload Window**

---

## Manual install

```bash
git clone https://github.com/arielmoatti/claude-code-ui-extras.git
cd claude-code-ui-extras
bash inject-ui.sh
```

Reload VS Code after running.

## Customize border color

Edit `ui.conf` before running the script:

```
border_color=rgba(249,131,131,0.5)
```

Accepts any valid CSS color — hex, rgb, rgba, hsl.
Re-run the script after changing.

## Usage

| Action | Result |
|--------|--------|
| Click ↑ / ↓ | Jump to previous / next user message |
| Right-click ↑ or ↓ | Toggle the message border on/off |

## Re-run after Claude Code updates

Claude Code updates overwrite the injected files. Just run the script again:

```bash
bash scripts/inject-ui.sh
```

Then reload VS Code.
