param(
  [Parameter(Mandatory = $true)][string]$Role,
  [Parameter(Mandatory = $true)][ValidateSet('codex', 'claude', 'pi')][string]$Cli,
  [Parameter(Mandatory = $true)][string]$Model,
  [string]$Effort = '',
  [Parameter(Mandatory = $true)][string]$Mission,
  [Parameter(Mandatory = $true)][string]$Result,
  [Parameter(Mandatory = $true)][string]$Log,
  [string]$Cwd = '.',
  [string]$CliExe = '',
  [string]$CliScript = ''
)

Set-Location -LiteralPath $Cwd

if (-not (Test-Path -LiteralPath $Mission)) {
  Set-Content -LiteralPath $Result -Value "# 임무 파일 없음`n`n$Mission"
  Set-Content -LiteralPath "$Result.done" -Value "2"
  exit 2
}

$prompt = Get-Content -Raw -LiteralPath $Mission
if ($Cli -eq 'codex') {
  $prompt += "`n`n[do-it] 최종 응답 메시지에 전체 산출물을 담으십시오. 메시지는 결과 파일로 자동 저장됩니다."
}
else {
  $prompt += "`n`n[do-it] 작업이 끝나면 최종 산출물을 다음 경로에 마크다운으로 저장하십시오: $Result"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Result) | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Log) | Out-Null

# npm 래퍼(.ps1/.cmd)는 종료 코드를 $LASTEXITCODE로 노출하지 못하므로
# 실제 네이티브 진입점(node + cli.js, claude.exe)으로 우회한다.
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
        return @{ Exe = $null; Script = $js }
      }
    }
    return @{ Exe = $src; Script = '' }
  }
  return @{ Exe = $src; Script = '' }
}

$code = 1
try {
  $exe = $CliExe
  $script = $CliScript
  if (-not $exe -and -not $script) {
    $inv = Get-NativeEntry $Cli
    $exe = $inv.Exe
    $script = $inv.Script
  }

  switch ($Cli) {
    'codex' {
      $flags = @('exec', '-m', $Model, '-s', 'workspace-write', '--skip-git-repo-check', '-o', $Result)
      if ($Effort) { $flags += @('-c', "model_reasoning_effort=`"$Effort`"") }
      $flags += @('-')
    }
    'claude' {
      $flags = @('-p', '--model', $Model, '--permission-mode', 'bypassPermissions', '--output-format', 'text')
      if ($Effort) { $flags += @('--effort', $Effort) }
    }
    'pi' {
      $flags = @('-p', '--model', $Model, '--no-session', '--name', $Role)
    }
  }

  if ($script) {
    $node = (Get-Command node -ErrorAction SilentlyContinue).Source
    if (-not $node) { throw 'node를 찾을 수 없습니다' }
    $prompt | & $node @($script + $flags) 2>&1 | Tee-Object -FilePath $Log
  }
  else {
    $prompt | & $exe @flags 2>&1 | Tee-Object -FilePath $Log
  }
  $code = $LASTEXITCODE
}
catch {
  $err = $_.Exception.Message
  Add-Content -LiteralPath $Log -Value "`n[do-it] 실행 오류: $err"
  Set-Content -LiteralPath $Result -Value "# 실행 오류`n`n$err"
  Set-Content -LiteralPath "$Result.done" -Value "1"
  exit 1
}

if (-not (Test-Path -LiteralPath $Result)) {
  $tail = (Get-Content -LiteralPath $Log -Tail 300 -ErrorAction SilentlyContinue) -join "`n"
  Set-Content -LiteralPath $Result -Value "# 산출물 누락`n`n에이전트가 산출물을 저장하지 않았습니다. 로그 마지막 300줄:`n````text`n$tail`n````"
}

if ($null -eq $code -or $code -eq '') { $code = 0 }
Set-Content -LiteralPath "$Result.done" -Value "$code"
exit $code
