#!/usr/bin/env pwsh
# Install or update the `render-formulas` skill into the personal Claude Code skills dir.
# Re-running this fetches the latest version (install and update are identical).
$ErrorActionPreference = 'Stop'

$dest = Join-Path $env:USERPROFILE '.claude\skills\render-formulas'
$base = 'https://raw.githubusercontent.com/zer0ken/skills/main/claude/render-formulas'

# Protect a developer's symlinked/junctioned working copy from being clobbered.
if ((Test-Path $dest) -and ((Get-Item $dest -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Write-Error "Refusing to overwrite $dest - it is a symlink/junction (developer setup). Edit the source repo directly."
}

New-Item -ItemType Directory -Force -Path (Join-Path $dest 'scripts') | Out-Null
Invoke-WebRequest -Uri "$base/SKILL.md"                -OutFile (Join-Path $dest 'SKILL.md')
Invoke-WebRequest -Uri "$base/scripts/pnglatex"        -OutFile (Join-Path $dest 'scripts\pnglatex')
Invoke-WebRequest -Uri "$base/scripts/show-formula.sh" -OutFile (Join-Path $dest 'scripts\show-formula.sh')
Invoke-WebRequest -Uri "$base/scripts/show-passage.sh" -OutFile (Join-Path $dest 'scripts\show-passage.sh')

Write-Host "render-formulas skill installed/updated at $dest"
Write-Host "One-time toolchain: scoop install latex imagemagick   (needs latex, dvipng, imagemagick on PATH)"
Write-Host "Restart Claude Code (or open a new session) to pick it up."
