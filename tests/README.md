Test agent for Internet Optimizer

- `run_smoke_test.ps1`: Creates a safe test copy of `Internet_Optimizer_Authenticated.bat` (destructive commands replaced) and runs it to exercise control flow without changing system settings.
- `run_all_tests.ps1`: Convenience runner for all tests (currently only smoke test).

Usage (from repository):

PowerShell (recommended):

```powershell
cd NetworkOps\tests
pwsh -NoProfile -ExecutionPolicy Bypass -File run_all_tests.ps1
```

Notes:
- The smoke test intentionally replaces potentially destructive commands (netsh, reg, checkpoint) with harmless echo statements.
- The test writes a copy of the modified batch and an output log to `%TEMP%`.
- Extend `run_smoke_test.ps1` to add further checks or integrate with CI systems.
