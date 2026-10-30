#!/usr/bin/env pwsh
# Install or update the rv skill.
$ErrorActionPreference = 'Stop'

$dest = Join-Path $env:USERPROFILE '.claude\skills\rv'
$src = 'https://raw.githubusercontent.com/zer0ken/skills/main/claude/rv'

if ((Test-Path $dest) -and ((Get-Item $dest -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Write-Error "Refusing to overwrite $dest - it is a symlink/junction (developer setup). Edit the source repo directly."
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Invoke-WebRequest -Uri "$src/SKILL.md" -OutFile (Join-Path $dest 'SKILL.md')

Write-Host "rv skill installed/updated at $dest"
Write-Host 'Restart the agent (or open a new session) to pick it up, then use /rv'
