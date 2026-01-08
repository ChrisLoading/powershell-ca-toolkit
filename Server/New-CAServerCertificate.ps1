# Run as Administrator
$rootSubject   = 'CN=Corp-Root-CA'
$dns           = @('devops.corp.contoso.com','win2016')
$serverDays    = 397
$friendlyName  = 'IIS - devops.corp.contoso.com'

# 先從 Trusted Root / Personal 找 Root
$root = Get-ChildItem Cert:\LocalMachine\Root | Where-Object Subject -eq $rootSubject | Select-Object -First 1
if (-not $root) {
  $root = Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -eq $rootSubject | Select-Object -First 1
}
if (-not $root) { throw "Root CA '$rootSubject' not found. Run CA-New-Root.ps1 first." }

# 檢查是否已有合適的同 CN 憑證
$cn = $dns[0]
$existing = Get-ChildItem Cert:\LocalMachine\My |
            Where-Object { $_.Subject -eq "CN=$cn" } |
            Sort-Object NotAfter -Descending |
            Select-Object -First 1

$serverCert = $existing
$needNew = $true
if ($existing) {
  $hasAllSan = $true
  foreach ($d in $dns) {
    if ($existing.DnsNameList.Unicode -notcontains $d) { $hasAllSan = $false; break }
  }
  $validEnough = ($existing.NotAfter -gt (Get-Date).AddDays(30))
  if ($hasAllSan -and $validEnough) { $needNew = $false }
}

if ($needNew) {
  $serverCert = New-SelfSignedCertificate `
    -Type SSLServerAuthentication `
    -DnsName $dns `
    -CertStoreLocation 'Cert:\LocalMachine\My' `
    -Signer $root `
    -HashAlgorithm sha256 `
    -KeyLength 4096 `
    -KeyUsage DigitalSignature, KeyEncipherment `
    -NotAfter (Get-Date).AddDays($serverDays) `
    -FriendlyName $friendlyName
  Write-Host "Issued new server cert: $($serverCert.Thumbprint)"
} else {
  Write-Host "Reuse existing server cert: $($serverCert.Thumbprint)"
}

Write-Host "Server Cert Subject: $($serverCert.Subject)"
Write-Host "SANs               : $($serverCert.DnsNameList.Unicode -join ', ')"
Write-Host "Expires            : $($serverCert.NotAfter)"

Read-Host "Press Enter to continue..."