@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Authenticated Internet Optimizer

REM Authentication model:
REM - This batch file requires Windows UAC administrator authentication.
REM - It does not store or ask for a plaintext password.

set "BACKUP_ROOT=%USERPROFILE%\Desktop\InternetOptimizerBackup"
if not exist "%USERPROFILE%\Desktop" set "BACKUP_ROOT=%USERPROFILE%\Documents\InternetOptimizerBackup"
if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%" >nul 2>&1
set "LOG_FILE=%BACKUP_ROOT%\internet_optimizer.log"

call :RequireAdmin

:Menu
cls
call :Header
echo.
echo   1. Apply recommended internet optimizations
echo   2. Apply optional low-latency gaming tweaks
echo   3. Set DNS servers
echo   4. Restore Windows network defaults
echo   5. Save current network status to log
echo   0. Exit
echo.
choice /c 123450 /n /m "Select an option: "
if errorlevel 6 goto End
if errorlevel 5 goto ShowState
if errorlevel 4 goto RestoreDefaults
if errorlevel 3 goto DnsMenu
if errorlevel 2 goto GamingTweaks
if errorlevel 1 goto Recommended
goto Menu

:Recommended
cls
call :Header
echo.
echo This will back up current settings, flush network caches, reset Winsock/IP,
echo and apply conservative TCP settings.
echo.
choice /c YN /m "Continue"
if errorlevel 2 goto Menu
call :BackupState
call :Run ipconfig /flushdns
call :Run ipconfig /registerdns
call :Run nbtstat -R
call :Run nbtstat -RR
call :Run arp -d *
call :Run netsh winsock reset
call :Run netsh int ip reset
call :Run netsh int tcp set heuristics disabled
call :Run netsh int tcp set global autotuninglevel=normal
call :Run netsh int tcp set global rss=enabled
call :Run netsh int tcp set global rsc=enabled
call :Run netsh int tcp set global ecncapability=disabled
call :Run netsh int tcp set global timestamps=disabled
call :Run netsh int tcp set global initialrto=2000
echo.
echo Recommended optimizations finished. Restart Windows before judging results.
echo Log: "%LOG_FILE%"
pause
goto Menu

:GamingTweaks
cls
call :Header
echo.
echo Optional low-latency tweaks can help some games but may reduce throughput on
echo some networks. They are separated from the recommended profile on purpose.
echo.
choice /c YN /m "Apply low-latency gaming tweaks"
if errorlevel 2 goto Menu
call :BackupState
call :Run reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f
call :Run reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 0 /f
call :Run powershell -NoProfile -ExecutionPolicy Bypass -Command "$base='HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'; Get-ChildItem $base | ForEach-Object { New-ItemProperty -Path $_.PSPath -Name TcpAckFrequency -Value 1 -PropertyType DWord -Force | Out-Null; New-ItemProperty -Path $_.PSPath -Name TCPNoDelay -Value 1 -PropertyType DWord -Force | Out-Null; New-ItemProperty -Path $_.PSPath -Name TcpDelAckTicks -Value 0 -PropertyType DWord -Force | Out-Null }"
echo.
echo Gaming tweaks finished. Restart Windows before judging results.
echo Log: "%LOG_FILE%"
pause
goto Menu

:DnsMenu
cls
call :Header
echo.
echo   1. Cloudflare DNS    1.1.1.1 / 1.0.0.1
echo   2. Google DNS        8.8.8.8 / 8.8.4.4
echo   3. Quad9 DNS         9.9.9.9 / 149.112.112.112
echo   4. Restore automatic DNS from router/ISP
echo   0. Back
echo.
choice /c 12340 /n /m "Select DNS option: "
if errorlevel 5 goto Menu
if errorlevel 4 goto DnsAutomatic
if errorlevel 3 (
    set "DNS1=9.9.9.9"
    set "DNS2=149.112.112.112"
    goto DnsApply
)
if errorlevel 2 (
    set "DNS1=8.8.8.8"
    set "DNS2=8.8.4.4"
    goto DnsApply
)
if errorlevel 1 (
    set "DNS1=1.1.1.1"
    set "DNS2=1.0.0.1"
    goto DnsApply
)
goto DnsMenu

:DnsApply
call :BackupState
call :Run powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ('%DNS1%','%DNS2%') }"
call :Run ipconfig /flushdns
echo.
echo DNS set to %DNS1% and %DNS2% on active network adapters.
echo Log: "%LOG_FILE%"
pause
goto Menu

:DnsAutomatic
call :BackupState
call :Run powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses }"
call :Run ipconfig /flushdns
echo.
echo DNS restored to automatic on active network adapters.
echo Log: "%LOG_FILE%"
pause
goto Menu

:RestoreDefaults
cls
call :Header
echo.
echo This resets DNS to automatic, restores conservative Windows TCP defaults,
echo and removes the optional low-latency registry tweaks.
echo.
choice /c YN /m "Continue"
if errorlevel 2 goto Menu
call :BackupState
call :Run powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses }"
call :Run netsh winsock reset
call :Run netsh int ip reset
call :Run netsh int tcp set heuristics default
call :Run netsh int tcp set global autotuninglevel=normal
call :Run netsh int tcp set global rss=enabled
call :Run netsh int tcp set global rsc=enabled
call :Run netsh int tcp set global ecncapability=default
call :Run netsh int tcp set global timestamps=default
call :Run reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f
call :Run reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 20 /f
call :Run powershell -NoProfile -ExecutionPolicy Bypass -Command "$base='HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'; Get-ChildItem $base | ForEach-Object { Remove-ItemProperty -Path $_.PSPath -Name TcpAckFrequency,TCPNoDelay,TcpDelAckTicks -ErrorAction SilentlyContinue }"
call :Run ipconfig /flushdns
echo.
echo Restore finished. Restart Windows before judging results.
echo Log: "%LOG_FILE%"
pause
goto Menu

:ShowState
cls
call :Header
echo.
echo Saving current network status to the log.
call :Run whoami
call :Run ipconfig /all
call :Run netsh int tcp show global
call :Run netsh int tcp show heuristics
call :Run powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | Format-Table -AutoSize; Get-DnsClientServerAddress | Format-Table -AutoSize"
echo.
echo Current network status saved to:
echo "%LOG_FILE%"
pause
goto Menu

:RequireAdmin
net session >nul 2>&1
if "%ERRORLEVEL%"=="0" exit /b 0
echo Requesting Windows administrator authentication...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
exit /b

:BackupState
echo.
echo Creating backup and restore point where available...
if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%" >nul 2>&1
call :Run powershell -NoProfile -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'Before Internet Optimizer' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop"
call :Run reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" "%BACKUP_ROOT%\Tcpip_Parameters.reg" /y
call :Run reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "%BACKUP_ROOT%\SystemProfile.reg" /y
call :Run netsh int tcp show global
call :Run netsh int tcp show heuristics
call :Run ipconfig /all
exit /b 0

:Run
echo.
echo ^> %*
>>"%LOG_FILE%" echo.
>>"%LOG_FILE%" echo [%DATE% %TIME%] ^> %*
%* >>"%LOG_FILE%" 2>&1
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo Command returned %RC%. Details were written to the log.
    >>"%LOG_FILE%" echo Command returned %RC%.
) else (
    echo OK
)
exit /b %RC%

:Header
echo Authenticated Internet Optimizer
echo Running as: %USERDOMAIN%\%USERNAME%
echo Backup folder: "%BACKUP_ROOT%"
echo Log file: "%LOG_FILE%"
exit /b 0

:End
endlocal
exit /b 0
