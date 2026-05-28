# Safe smoke test for Internet_Optimizer_Authenticated.bat
# Creates a test copy with destructive commands replaced and runs it.

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$sourcePath = Resolve-Path (Join-Path $scriptRoot '..\Internet_Optimizer_Authenticated.bat') -ErrorAction Stop
$source = Get-Content $sourcePath -Raw

# Make safe replacements
$replacements = @(
    @{pattern = 'call :RequireAdmin "%~1"'; repl = 'rem TEST-SAFE: skipped RequireAdmin'},
    @{pattern = '(?i)call :Run powershell -NoProfile -ExecutionPolicy Bypass -Command "Checkpoint-Computer.*"'; repl = 'echo SKIPPED CHECKPOINT-COMPUTER'},
    @{pattern = '(?i)call :Run reg export .*'; repl = 'echo SKIPPED REG EXPORT'},
    @{pattern = '(?i)call :Run reg add .*'; repl = 'echo SKIPPED REG ADD'},
    @{pattern = '(?i)call :Run netsh .*'; repl = 'echo SKIPPED NETSH'},
    @{pattern = '(?i)call :Run ipconfig /registerdns'; repl = 'echo SKIPPED IPCONFIG REGISTERDNS'},
    @{pattern = '(?i)call :Run nbtstat .*'; repl = 'echo SKIPPED NBTSTAT'},
    @{pattern = '(?i)call :Run arp .*'; repl = 'echo SKIPPED ARP'},
    @{pattern = '(?i)call :Run ipconfig /flushdns'; repl = 'echo SKIPPED IPCONFIG FLUSHDNS'},
    @{pattern = '(?i)pause'; repl = 'rem SKIPPED PAUSE'}
)

foreach ($r in $replacements) {
    $source = [regex]::Replace($source, $r.pattern, $r.repl)
}

# Force backup/log paths to temp to avoid touching user files
$source = [regex]::Replace($source, 'set "BACKUP_ROOT=.*"', 'set "BACKUP_ROOT=%TEMP%\\InternetOptimizerBackup_TEST"')
$source = [regex]::Replace($source, 'set "LOG_FILE=.*"', 'set "LOG_FILE=%BACKUP_ROOT%\\internet_optimizer_test.log"')

# Remove elevation relaunch to avoid UAC popups
$source = $source -replace 'powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath \$env:SCRIPT_PATH -ArgumentList ''--elevated'' -WorkingDirectory \$env:SCRIPT_DIR -Verb RunAs"', 'rem SKIPPED UAC relaunch'

$testFile = Join-Path $env:TEMP 'Internet_Optimizer_Authenticated_test.bat'
Set-Content -Path $testFile -Value $source -Encoding ASCII

Write-Host "Running safe test batch at: $testFile"

# Execute and capture output
$procOutput = & cmd /c `"$testFile`" 2>&1 | Out-String
$exitCode = $LASTEXITCODE

# Save output to temp log for inspection
$logPath = Join-Path $env:TEMP 'Internet_Optimizer_Authenticated_test_output.txt'
Set-Content -Path $logPath -Value $procOutput -Encoding UTF8

# Simple checks: menu presence and header
$passed = $false
if ($procOutput -match 'Authenticated Internet Optimizer' -and $procOutput -match 'Select an option') {
    $passed = $true
}

if ($passed) {
    Write-Host "SMOKE TEST PASSED"
    exit 0
} else {
    Write-Host "SMOKE TEST FAILED"
    Write-Host "Output saved to: $logPath"
    exit 2
}
