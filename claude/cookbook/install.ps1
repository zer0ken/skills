#!/usr/bin/env pwsh
# Install or update the `cookbook` skill into the personal Claude Code skills dir.
# Re-running this fetches the latest version (install and update are identical).
$ErrorActionPreference = 'Stop'

$dest = Join-Path $env:USERPROFILE '.claude\skills\cookbook'
$src  = 'https://raw.githubusercontent.com/zer0ken/skills/main/claude/cookbook/SKILL.md'

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Invoke-WebRequest -Uri $src -OutFile (Join-Path $dest 'SKILL.md')

Write-Host "cookbook skill installed/updated at $dest"
Write-Host "Restart Claude Code (or open a new session) to pick it up, then run /cookbook"
