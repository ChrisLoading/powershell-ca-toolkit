# --- self-elevate (Add hosts/dns require admin) ---
# 自動提權（以系統管理員重啟另一終端機, 並關閉原終端）
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

# 避免重複寫入
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
$entries = @(
    "192.168.XXX.XXX`tdevops.corp.contoso.com",
    "192.168.XXX.XXX`twin2016"
)
$ErrorActionPreference = 'Stop'  # 讓錯誤會中止（可被 try/catch 捕捉）

if (-not (Test-Path $hosts)) { throw "hosts not found: $hosts" }

$needUpdate = $false
foreach ($entry in $entries) {
    # escape 用正規表達式比對，確保不是註解 (# 開頭)
    $pattern = '^(?!\s*#)\s*' + [Regex]::Escape($entry).Replace('\t','\s+') + '(\s+|$)'
    if (-not (Select-String -Path $hosts -Pattern $pattern -Quiet)) {
        $needUpdate = $true
    }
}

if ($needUpdate) {
    # 備份
    Copy-Item $hosts "$hosts.bak_$(Get-Date -Format yyyyMMddHHmmss)" -Force

    # 解除唯讀（若有）
    $fi = Get-Item -LiteralPath $hosts -Force
    if ($fi.Attributes -band [IO.FileAttributes]::ReadOnly) {
        Set-ItemProperty -LiteralPath $hosts -Name Attributes -Value ($fi.Attributes -bxor [IO.FileAttributes]::ReadOnly)
    }

    # 以 ASCII 寫入 + CRLF
    foreach ($entry in $entries) {
        $pattern = '^(?!\s*#)\s*' + [Regex]::Escape($entry).Replace('\t','\s+') + '(\s+|$)'
        if (-not (Select-String -Path $hosts -Pattern $pattern -Quiet)) {
            Add-Content -Path $hosts -Value "`r`n$entry" -Encoding Ascii
        }
    }

    # flush DNS cache
    ipconfig /flushdns | Out-Null
    Write-Host "Hosts updated and DNS cache flushed.`n" -ForegroundColor Green
} else {
    Write-Host "All entries already exist.`n" -ForegroundColor Yellow
}

# 驗證
Resolve-DnsName devops.corp.contoso.com
Resolve-DnsName win2016
Test-NetConnection devops.corp.contoso.com -Port 443
Test-NetConnection win2016 -Port 443
Read-Host "`nCheck result. Press Enter to exit"
