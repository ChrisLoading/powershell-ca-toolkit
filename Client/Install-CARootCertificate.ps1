# Run as Administrator on each client machine
$cerPath = '.\Corp-Root-CA.cer'  # 把檔案複製到本機，或指向共享路徑

try {
    if (-not (Test-Path $cerPath)) {
        throw "File not found: $cerPath"
    }
}
catch {
    Write-Error $_
    Read-Host "Press Enter to exit"
}

# 匯入到「本機電腦」→「受信任的根憑證授權單位」
Import-Certificate -FilePath $cerPath -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null
Write-Host "Trusted Root installed."

# 驗證一下
$ok = Get-ChildItem Cert:\LocalMachine\Root | Where-Object Subject -eq 'CN=Corp-Root-CA'
if ($ok) { Write-Host "Verify: Corp-Root-CA present in Trusted Root." } else { throw "Verify failed." }

Pause