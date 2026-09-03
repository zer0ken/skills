#!/usr/bin/env pwsh
# Install or update the `korean-mode` skill into the personal Claude Code skills dir.
# Re-running this fetches the latest version (install and update are identical).
$ErrorActionPreference = 'Stop'

$dest = Join-Path $env:USERPROFILE '.claude\skills\korean-mode'
$base = 'https://raw.githubusercontent.com/zer0ken/skills/main/claude/korean-mode'

# Protect a developer's symlinked/junctioned working copy from being clobbered.
if ((Test-Path $dest) -and ((Get-Item $dest -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Write-Error "Refusing to overwrite $dest - it is a symlink/junction (developer setup). Edit the source repo directly."
}

New-Item -ItemType Directory -Force -Path (Join-Path $dest 'scripts') | Out-Null
Invoke-WebRequest -Uri "$base/SKILL.md"                -OutFile (Join-Path $dest 'SKILL.md')
Invoke-WebRequest -Uri "$base/RULES.md"                -OutFile (Join-Path $dest 'RULES.md')
Invoke-WebRequest -Uri "$base/scripts/toggle.mjs"      -OutFile (Join-Path $dest 'scripts\toggle.mjs')
Invoke-WebRequest -Uri "$base/scripts/prompt-hook.sh"  -OutFile (Join-Path $dest 'scripts\prompt-hook.sh')

Write-Host "korean-mode skill installed/updated at $dest"
Write-Host "Needs Node.js and Git Bash on PATH."
Write-Host "Restart Claude Code (or open a new session) to pick it up, then run /korean-mode"
