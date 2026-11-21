# Disables the automatic opening of the magazine.
# Right-click this file -> "Run with PowerShell".
try {
  Unregister-ScheduledTask -TaskName "Gaming Daily" -Confirm:$false
  Write-Host "OK - Automatic opening is disabled." -ForegroundColor Green
} catch {
  Write-Host "Nothing to disable (the task did not exist)." -ForegroundColor Yellow
}
Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
