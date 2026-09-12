param(
    [string]$SysmonPath = "C:\Tools\Sysmon"
)

$ErrorActionPreference = "Stop"

Write-Host "[*] Downloading Sysmon..."
$sysmonUrl = "https://download.sysinternals.com/files/Sysmon.zip"
$zipPath = "$env:TEMP\Sysmon.zip"
$sysmonConfigUrl = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"
$configPath = "$SysmonPath\sysmonconfig.xml"

if (-not (Test-Path $SysmonPath)) {
    New-Item -ItemType Directory -Path $SysmonPath -Force | Out-Null
}

Invoke-WebRequest -Uri $sysmonUrl -OutFile $zipPath
Expand-Archive -Path $zipPath -DestinationPath $SysmonPath -Force
Remove-Item $zipPath

Write-Host "[*] Downloading SwiftOnSecurity sysmon config..."
Invoke-WebRequest -Uri $sysmonConfigUrl -OutFile $configPath

Write-Host "[*] Installing Sysmon with config..."
$sysmonExe = Get-ChildItem -Path $SysmonPath -Filter "Sysmon64.exe" -Recurse | Select-Object -First 1
if (-not $sysmonExe) {
    $sysmonExe = Get-ChildItem -Path $SysmonPath -Filter "Sysmon.exe" -Recurse | Select-Object -First 1
}

Start-Process -FilePath $sysmonExe.FullName -ArgumentList "-i", $configPath, "-accepteula" -Verb RunAs -Wait

Write-Host "[+] Sysmon installed and running with SwiftOnSecurity config"
Write-Host "[+] Event logs: Microsoft-Windows-Sysmon/Operational"
