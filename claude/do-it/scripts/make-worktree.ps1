param(
  [Parameter(Mandatory = $true)][string]$Repo,
  [Parameter(Mandatory = $true)][string]$Branch,
  [Parameter(Mandatory = $true)][string]$Path,
  [string]$Base = ''
)

$ErrorActionPreference = 'Stop'
Push-Location -LiteralPath $Repo
try {
  $gitArgs = @('worktree', 'add', '-b', $Branch, $Path)
  if ($Base) { $gitArgs += $Base }
  git @gitArgs
  exit $LASTEXITCODE
}
finally {
  Pop-Location
}
