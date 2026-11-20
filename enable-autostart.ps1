# Enables opening the magazine automatically every morning at 08:00.
# Right-click this file -> "Run with PowerShell".
$exe = Join-Path $PSScriptRoot "GamingDaily.exe"
try {
  $action  = New-ScheduledTaskAction -Execute $exe
  $trigger = New-ScheduledTaskTrigger -Daily -At 8:00am
  $set     = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10)
  Register-ScheduledTask -TaskName "Gaming Daily" -Action $action -Trigger $trigger -Settings $set -Description "Opens the gaming magazine every morning" -Force | Out-Null
  Write-Host "OK - The magazine will open automatically every day at 08:00 (or at next startup if the PC was off)." -ForegroundColor Green
} catch {
  Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
