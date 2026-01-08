# Run as Administrator on the server that holds the Root
$rootSubject = 'CN=Corp-Root-CA'
$destDir     = '.\Cert'

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
}

try {
    $root = Get-ChildItem Cert:\LocalMachine\Root |
            Where-Object Subject -eq $rootSubject |
            Select-Object -First 1
    if (-not $root) {
      $root = Get-ChildItem Cert:\LocalMachine\My | Where-Object Subject -eq $rootSubject | Select-Object -First 1
    }
    if (-not $root) { throw "Root CA '$rootSubject' not found in LocalMachine\Root." }
}
catch {
    Write-Error $_
    Read-Host "Press Enter to exit"
    exit 1
}

$cerPath = Join-Path $destDir 'Corp-Root-CA.cer'
Export-Certificate -Cert $root -FilePath $cerPath -Force | Out-Null
Write-Host "Exported Root public cert to: $cerPath"

Pause
# Read-Host "Press Enter to continue..."