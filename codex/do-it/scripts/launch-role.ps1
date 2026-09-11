param(
  [Parameter(Mandatory = $true)][string]$Session,
  [Parameter(Mandatory = $true)][string]$Role,
  [Parameter(Mandatory = $true)][ValidateSet('codex', 'claude', 'pi')][string]$Cli,
  [Parameter(Mandatory = $true)][string]$Model,
  [string]$Effort = '',
  [Parameter(Mandatory = $true)][string]$Cwd,
  [Parameter(Mandatory = $true)][string]$Mission,
  [Parameter(Mandatory = $true)][string]$Result,
  [Parameter(Mandatory = $true)][string]$Log
)

$ErrorActionPreference = 'Stop'
$run = Join-Path $PSScriptRoot 'run-role.ps1'

# 세션 존재 확인, 없으면 생성
tmux has-session -t $Session *> $null
if ($LASTEXITCODE -ne 0) {
  tmux new-session -d -s $Session *> $null
  if ($LASTEXITCODE -ne 0) {
    Write-Error "tmux 세션 생성 실패: $Session"
    exit 1
  }
  tmux set -g remain-on-exit on *> $null
}

# 같은 이름의 기존 윈도우 제거
$windows = tmux list-windows -t $Session 2>$null
foreach ($line in $windows) {
  if ($line -match "^(\d+): $Role([ *-]|$)") {
    tmux kill-window -t "$Session`:$Role" *> $null
  }
}

# CLI 네이티브 진입점 해석. npm 래퍼(.ps1)는 node + 실제 cli.js로 우회한다.
function Get-NativeEntry([string]$Name) {
  $cmd = Get-Command $Name -ErrorAction SilentlyContinue
  if (-not $cmd) { throw "CLI를 찾을 수 없습니다: $Name" }
  $src = $cmd.Source
  if ($src -match '(?i)\.(ps1|cmd|bat)$') {
    $npm = Split-Path -Parent $src
    $rel = switch ($Name) {
      'codex' { 'node_modules\@openai\codex\bin\codex.js' }
      'pi'    { 'node_modules\@earendil-works\pi-coding-agent\dist\cli.js' }
      default { '' }
    }
    if ($rel) {
      $js = Join-Path $npm $rel
      if (Test-Path -LiteralPath $js) {
        return @{ Exe = ''; Script = $js }
      }
    }
    return @{ Exe = $src; Script = '' }
  }
  return @{ Exe = $src; Script = '' }
}

$inv = Get-NativeEntry $Cli
$runArgs = @(
  '-Role', $Role, '-Cli', $Cli, '-Model', $Model,
  '-Mission', $Mission, '-Result', $Result, '-Log', $Log, '-Cwd', $Cwd
)
if ($Effort) { $runArgs += @('-Effort', $Effort) }
if ($inv.Script) { $runArgs += @('-CliScript', $inv.Script) }
elseif ($inv.Exe) { $runArgs += @('-CliExe', $inv.Exe) }

# 윈도우 생성. 인자 토큰에 공백이 없어야 한다.
$arg = @(
  'new-window', '-t', $Session, '-n', $Role, '-c', $Cwd, '--',
  'pwsh', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $run
) + $runArgs

& tmux @arg
exit $LASTEXITCODE
