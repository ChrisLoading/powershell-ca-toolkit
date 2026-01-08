# --- self-elevate (As the head of the script) ---
# 自動提權（不是系統管理員就自我重啟）
# if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
# ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
#   $argsList = @(
#     '-NoProfile','-ExecutionPolicy','Bypass',
#     '-File',('"{0}"' -f $PSCommandPath)
#   )
#   Start-Process -FilePath 'powershell.exe' -ArgumentList $argsList -Verb RunAs
#   exit
# }
# --- main ---

Get-ChildItem Cert:\LocalMachine\Root |
  Where-Object { $_.Subject -match 'CN=Corp-Root-CA' } |
  Select-Object Subject, Thumbprint, NotAfter

Pause