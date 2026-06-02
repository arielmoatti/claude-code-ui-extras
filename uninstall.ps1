# ============================================================================
#  Claude Code UI Extras - uninstaller
#  Removes everything this pack installs:
#    - every injected "Claude UI Extras <X> Start/End" block (CSS / JS / Shim,
#      and any future block) from all Claude Code webview bundles
#    - the deployed scripts (inject-ui.sh, ui.conf, bypass-claude-dir.js, state)
#    - the SessionStart + PermissionRequest hooks from settings.json
#  Safe, idempotent, and scoped: it never touches the separate "Claude RTL"
#  pack. Every file it edits is backed up alongside as .bak.<timestamp>.
#
#  Run (PowerShell):
#    irm https://raw.githubusercontent.com/arielmoatti/claude-code-ui-extras/main/uninstall.ps1 | iex
# ============================================================================
$ErrorActionPreference = 'Stop'
$stamp = Get-Date -Format 'yyyyMMddHHmmss'
$home_ = $env:USERPROFILE
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
Write-Host "== Claude Code UI Extras - uninstaller =="

# 1. Strip ALL "Claude UI Extras <name> Start/End" blocks from every webview bundle.
#    Generic by design: one regex covers Patch (CSS), JS, Shim, and anything added
#    later, so this script never needs editing when new blocks are introduced.
#    .NET read/write keeps UTF-8 without a BOM (won't corrupt adjacent Hebrew, won't
#    prepend a BOM that would break the JS).
function Strip-AllBlocks($file, $label) {
  if (-not (Test-Path -LiteralPath $file)) { return }
  $text = [System.IO.File]::ReadAllText($file)
  $pattern = '(?s)\r?\n?/\* Claude UI Extras [\w ]+ Start \*/.*?/\* Claude UI Extras [\w ]+ End \*/\r?\n?'
  if ([regex]::IsMatch($text, $pattern)) {
    Copy-Item -LiteralPath $file "$file.bak.$stamp"
    $clean = [regex]::Replace($text, $pattern, "`n")
    [System.IO.File]::WriteAllText($file, $clean, $utf8NoBom)
    Write-Host "  cleaned $label  ->  $file"
  }
}
$webviews = Get-ChildItem "$home_\.vscode\extensions\anthropic.claude-code-*\webview" -Directory -ErrorAction SilentlyContinue
if (-not $webviews) { Write-Host "  no Claude Code webview folders found" }
foreach ($w in $webviews) {
  Strip-AllBlocks "$($w.FullName)\index.js"  "JS/Shim"
  Strip-AllBlocks "$($w.FullName)\index.css" "CSS"
}

# 2. Remove the deployed runtime files this pack drops into ~/.claude/scripts/.
$deployed = @(
  "$home_\.claude\scripts\inject-ui.sh",
  "$home_\.claude\scripts\ui.conf",
  "$home_\.claude\scripts\bypass-claude-dir.js",
  "$home_\.claude\scripts\.ui-extras-last-update-check"
)
foreach ($f in $deployed) {
  if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force; Write-Host "  deleted   ->  $f" }
}

# 3. Remove the two hooks from settings.json. Done via Node for reliable JSON
#    (Claude Code already ships/uses Node). Only entries whose command references
#    inject-ui.sh / bypass-claude-dir.js are touched; everything else is preserved.
$settings = "$home_\.claude\settings.json"
if (Test-Path -LiteralPath $settings) {
  Copy-Item -LiteralPath $settings "$settings.bak.$stamp"
  $njs = @'
var fs=require('fs');
var p=process.env.CC_SETTINGS;
var s;try{s=JSON.parse(fs.readFileSync(p,'utf8'));}catch(e){console.log('  settings.json unreadable - left unchanged');process.exit(0);}
if(!s.hooks){console.log('  no hooks block - nothing to remove');process.exit(0);}
function strip(list,needle){if(!Array.isArray(list))return list;return list.map(function(h){if(h&&Array.isArray(h.hooks)){h.hooks=h.hooks.filter(function(hh){return !(hh&&hh.command&&hh.command.indexOf(needle)!==-1);});}return h;}).filter(function(h){return h&&Array.isArray(h.hooks)?h.hooks.length>0:true;});}
if(s.hooks.SessionStart){s.hooks.SessionStart=strip(s.hooks.SessionStart,'inject-ui.sh');if(s.hooks.SessionStart.length===0)delete s.hooks.SessionStart;console.log('  removed SessionStart hook (inject-ui.sh)');}
if(s.hooks.PermissionRequest){s.hooks.PermissionRequest=strip(s.hooks.PermissionRequest,'bypass-claude-dir.js');if(s.hooks.PermissionRequest.length===0)delete s.hooks.PermissionRequest;console.log('  removed PermissionRequest hook (bypass-claude-dir.js)');}
if(Object.keys(s.hooks).length===0)delete s.hooks;
fs.writeFileSync(p,JSON.stringify(s,null,2)+'\n','utf8');
console.log('  settings.json cleaned (backup saved alongside)');
'@
  $tmp = "$env:TEMP\cc-uiextras-uninstall.js"
  [System.IO.File]::WriteAllText($tmp, $njs, $utf8NoBom)
  $env:CC_SETTINGS = $settings
  try { & node $tmp } catch { Write-Host "  (node not found - edit settings.json by hand to drop the inject-ui.sh / bypass-claude-dir.js hooks)" }
  Remove-Item -LiteralPath $tmp -ErrorAction SilentlyContinue
} else {
  Write-Host "  settings.json not present"
}

Write-Host ""
Write-Host "Done. Reload VSCode (Ctrl+Shift+P -> Developer: Reload Window) to drop the in-memory UI."
Write-Host "Every edited file was backed up alongside as .bak.$stamp"
