$logDir = "C:\Program Files (x86)\ossec-agent\logs"
$tempLog = "$env:TEMP\siem-test-alerts.log"

$alerts = @()

$srcIPs = @("10.0.0.15", "192.168.1.100", "172.16.0.50", "10.10.10.10", "192.168.56.101")
$usernames = @("admin", "root", "ubuntu", "testuser", "oracle")

for ($i = 1; $i -le 50; $i++) {
    $srcIP = $srcIPs[$i % $srcIPs.Count]
    $user = $usernames[$i % $usernames.Count]
    $timestamp = (Get-Date).AddSeconds(-$i * 30).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    switch ($i % 8) {
        0 { $alerts += "$timestamp SSH brute force attempt from $srcIP - Failed password for $user" }
        1 { $alerts += "$timestamp Port scan detected from $srcIP - multiple ports accessed" }
        2 { $alerts += "$timestamp PowerShell encoded command execution - IEX (New-Object Net.WebClient).DownloadString" }
        3 { $alerts += "$timestamp SSH login success for $user from $srcIP" }
        4 { $alerts += "$timestamp Suspicious process: winword.exe spawned cmd.exe" }
        5 { $alerts += "$timestamp Registry Run key modified: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" }
        6 { $alerts += "$timestamp Wazuh active response: firewall-drop triggered for $srcIP" }
        7 { $alerts += "$timestamp Failed sudo attempt for $user from $srcIP" }
    }
}

$alerts | Out-File -FilePath $tempLog -Encoding UTF8
Write-Host "[+] Generated $($alerts.Count) test alert entries"
Write-Host "[+] These simulate logs that Wazuh agents would send"
Write-Host ""
Write-Host "[!] To get real data, you need to:"
Write-Host "    1. Install a Wazuh agent on this machine or a VM"
Write-Host "    2. Run: .\agents\windows\install-agent.ps1 <MANAGER_IP>"
Write-Host "    3. Then run: .\config\atomic-red-team\windows\invoke-attacks.ps1"
