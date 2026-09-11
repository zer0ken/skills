param(
  [Parameter(Mandatory = $true)][string]$Done,
  [int]$TimeoutSec = 120,
  [int]$PollSec = 5
)

$deadline = (Get-Date).AddSeconds($TimeoutSec)
while (-not (Test-Path -LiteralPath $Done)) {
  if ((Get-Date) -gt $deadline) {
    Write-Output 'TIMEOUT'
    exit 1
  }
  Start-Sleep -Seconds $PollSec
}

Get-Content -Raw -LiteralPath $Done
exit 0
