#!/usr/bin/env pwsh
# Install or update the `pair` skill into the personal pi skills dir (~/.agents/skills).
# Re-running this fetches the latest version (install and update are identical).
$ErrorActionPreference = 'Stop'

$dest = Join-Path $env:USERPROFILE '.agents\skills\pair'
$base = 'https://raw.githubusercontent.com/zer0ken/skills/main/pi/pair'

# Protect a developer's symlinked/junctioned working copy from being clobbered.
if ((Test-Path $dest) -and ((Get-Item $dest -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Write-Error "Refusing to overwrite $dest - it is a symlink/junction (developer setup). Edit the source repo directly."
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Invoke-WebRequest -Uri "$base/SKILL.md" -OutFile (Join-Path $dest 'SKILL.md')
Invoke-WebRequest -Uri "$base/pair-select-advisor.sh" -OutFile (Join-Path $dest 'pair-select-advisor.sh')
Invoke-WebRequest -Uri "$base/pair-send.sh" -OutFile (Join-Path $dest 'pair-send.sh')

Write-Host "pair skill installed/updated at $dest"
Write-Host "Restart the agent (or open a new session) to pick it up, then run /pair"
