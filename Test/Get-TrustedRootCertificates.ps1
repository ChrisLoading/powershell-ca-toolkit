# --- self-elevate (As the head of the script) ---
# 自動提權（不是系統管理員即以系統管理員重啟另一終端機, 並關閉原終端）
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $argsList = @(
    '-NoProfile','-ExecutionPolicy','Bypass',
    '-File',('"{0}"' -f $PSCommandPath)
  )
  Start-Process -FilePath 'powershell.exe' -ArgumentList $argsList -Verb RunAs
  exit
}
# --- main ---

$certs = @(Get-ChildItem Cert:\LocalMachine\Root |
  Where-Object { $_.Subject -match 'CN=Corp-Root-CA' } |
  Select-Object Subject, Thumbprint, NotAfter)

$certs | Format-Table -AutoSize

Write-Host "Total Corp-Root-CA certificates found: $(@($certs).Count)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 