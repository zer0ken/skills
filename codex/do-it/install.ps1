#!/usr/bin/env pwsh
# Install or update the `do-it` skill into the personal Codex skills dir.
# Re-running this fetches the latest version (install and update are identical).
$ErrorActionPreference = 'Stop'
$dest = Join-Path $HOME '.codex/skills/do-it'
$base = 'https://raw.githubusercontent.com/zer0ken/skills/main/codex/do-it'

# Protect a developer's symlinked/junctioned working copy from being clobbered.
if ((Test-Path $dest) -and ((Get-Item $dest -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
    Write-Error "Refusing to overwrite $dest - it is a symlink/junction (developer setup). Edit the source repo directly."
}

New-Item -ItemType Directory -Force -Path (Join-Path $dest 'scripts') | Out-Null
Invoke-WebRequest -Uri "$base/SKILL.md" -OutFile (Join-Path $dest 'SKILL.md')
foreach ($s in @('launch-role.ps1', 'run-role.ps1', 'wait-role.ps1', 'make-worktree.ps1')) {
    Invoke-WebRequest -Uri "$base/scripts/$s" -OutFile (Join-Path $dest "scripts/$s")
}

Write-Host "do-it skill installed/updated at $dest"
Write-Host "Restart Codex (or open a new session) to pick it up, then invoke the do-it skill"
