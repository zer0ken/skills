#!/usr/bin/env pwsh
# Install or update the `eli5` skill into the personal pi skills dir (~/.agents/skills).
# Re-running this fetches the latest version (install and update are identical).
$ErrorActionPreference = 'Stop'

$dest = Join-Path $env:USERPROFILE '.agents\skills\eli5'
$src  = 'https://raw.githubusercontent.com/zer0ken/skills/main/pi/eli5/SKILL.md'

# Protect a developer's symlinked/junctioned working copy from being clobbered.
if ((Test-Path $dest) -and ((Get-Item $dest -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Write-Error "Refusing to overwrite $dest - it is a symlink/junction (developer setup). Edit the source repo directly."
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Invoke-WebRequest -Uri $src -OutFile (Join-Path $dest 'SKILL.md')

Write-Host "eli5 skill installed/updated at $dest"
Write-Host "Restart the agent (or open a new session) to pick it up, then run /eli5"
