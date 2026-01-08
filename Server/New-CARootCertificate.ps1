# Run as Administrator
$rootSubject = 'CN=Corp-Root-CA'
$rootYears   = 10
$outDir      = '.\Cert'
$rootCerPath = Join-Path $outDir 'Corp-Root-CA.cer'

$null = New-Item -ItemType Directory -Force $outDir

# 先找現有 Root
$root = Get-ChildItem Cert:\LocalMachine\Root | Where-Object Subject -eq $rootSubject | Select-Object -First 1
if (-not $root) {
  $root = Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -eq $rootSubject | Select-Object -First 1
}

# 沒有就建立
if (-not $root) {
  $root = New-SelfSignedCertificate `
    -Type Custom `
    -KeySpec Signature `
    -Subject $rootSubject `
    -KeyExportPolicy Exportable `
    -HashAlgorithm sha256 `
    -KeyLength 4096 `
    -CertStoreLocation 'Cert:\LocalMachine\My' `
    -KeyUsageProperty Sign `
    -KeyUsage CertSign,CRLSign `
    -NotAfter (Get-Date).AddYears($rootYears) `
    -TextExtension @('2.5.29.19={critical}{text}ca=true')   # BasicConstraints: CA=true
  Write-Host "Created new Root CA: $($root.Thumbprint)"
}

# 安裝到 Trusted Root
if (-not (Get-ChildItem Cert:\LocalMachine\Root | Where-Object Thumbprint -eq $root.Thumbprint)) {
  Export-Certificate -Cert $root -FilePath $rootCerPath -Force | Out-Null
  Import-Certificate -FilePath $rootCerPath -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null
  Write-Host "Imported Root CA into Trusted Root."
}

# 匯出 .cer
# if (-not (Test-Path $rootCerPath)) {
#   Export-Certificate -Cert $root -FilePath $rootCerPath -Force | Out-Null
# }
# Write-Host "Root CA ready. Thumbprint: $($root.Thumbprint)"
# Write-Host "Exported Root public cert to: $cerPath"

Read-Host "Press Enter to continue..."