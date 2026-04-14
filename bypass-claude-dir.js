/*
 * bypass-claude-dir.js — PermissionRequest hook
 *
 * Works around Claude Code's hardcoded `.claude/` guard that prompts for
 * Edit/Write/Bash inside .claude/ even when the session is in bypassPermissions mode
 * (see META issue anthropics/claude-code#39523).
 *
 * Auto-approves Edit/Write/MultiEdit/NotebookEdit on paths containing `.claude`,
 * and Bash commands whose text contains `.claude` — but ONLY when the session
 * is already in bypassPermissions mode. In any other mode (default/plan/acceptEdits)
 * the hook stays out of the way and normal dialogs appear.
 *
 * Installed by inject-ui.sh to ~/.claude/scripts/bypass-claude-dir.js
 * Registered as a PermissionRequest hook in ~/.claude/settings.json
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
