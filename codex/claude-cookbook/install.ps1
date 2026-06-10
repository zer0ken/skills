#!/usr/bin/env pwsh
# Install or update the `claude-cookbook` skill into the personal Codex skills dir.
# Re-running this fetches the latest version (install and update are identical).
$ErrorActionPreference = 'Stop'

$dest = Join-Path $env:USERPROFILE '.codex\skills\claude-cookbook'
$src  = 'https://raw.githubusercontent.com/zer0ken/skills/main/codex/claude-cookbook/SKILL.md'

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Invoke-WebRequest -Uri $src -OutFile (Join-Path $dest 'SKILL.md')

Write-Host "claude-cookbook skill installed/updated at $dest"
Write-Host "Restart Codex (or open a new session) to pick it up."
