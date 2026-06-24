# Authenticated Internet Optimizer

Authenticated Internet Optimizer is a Windows batch utility for backing up network settings, applying conservative TCP/DNS optimizations, and restoring defaults when needed. It is designed around traceability: every command is logged, settings are backed up before changes, and optional low-latency gaming tweaks are separated from the recommended profile.

## Features

- Requires administrator elevation through Windows UAC.
- Backs up TCP/IP and multimedia system profile registry keys before changes.
- Saves current network status with `ipconfig`, `netsh`, adapter, and DNS output.
- Applies conservative network cache resets and TCP global settings.
- Offers optional low-latency gaming registry tweaks as a separate action.
- Sets common DNS providers: Cloudflare, Google, Quad9, or automatic DNS.
- Restores Windows network defaults and removes optional low-latency tweaks.
- Logs all commands and exit codes to a desktop or documents backup folder.

## Menu Options

```text
1. Apply recommended internet optimizations
2. Apply optional low-latency gaming tweaks
3. Set DNS servers
4. Restore Windows network defaults
5. Save current network status to log
0. Exit
```

## Usage

Run the script from an elevated prompt or double-click it and accept the UAC prompt:

```bat
Internet_Optimizer_Authenticated.bat
```

Backups and logs are written to:

```text
%USERPROFILE%\Desktop\InternetOptimizerBackup
```

If the Desktop folder is unavailable, the script falls back to:

```text
%USERPROFILE%\Documents\InternetOptimizerBackup
```

## Safety Notes

Network tuning can affect stability, latency, and throughput differently across hardware and ISPs. This tool intentionally:

- Creates backups before registry and TCP/IP changes.
- Keeps optional gaming tweaks separate from the recommended profile.
- Provides a restore option for default Windows network settings.
- Logs command output so changes are auditable.

Restart Windows before judging optimization results.

## Tests

Smoke-test helpers live in `tests/`:

```powershell
.\tests\run_smoke_test.ps1
.\tests\run_all_tests.ps1
```

## License

All rights reserved unless a license is added later.
