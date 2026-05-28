# Runs all tests for Internet Optimizer (smoke test for now)
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$smoke = Join-Path $scriptRoot 'run_smoke_test.ps1'
if (-not (Test-Path $smoke)) { Write-Host 'Smoke test not found.'; exit 1 }

Write-Host 'Running smoke test...'
& powershell -NoProfile -ExecutionPolicy Bypass -File $smoke
$rc = $LASTEXITCODE
if ($rc -eq 0) { Write-Host 'All tests passed.'; exit 0 } else { Write-Host 'Some tests failed.'; exit $rc }
