param(
    [Parameter(Mandatory=$true)]
    [string]$ManagerIP,

    [string]$AgentName = $env:COMPUTERNAME,

    [string]$AgentGroup = "default"
)

$ErrorActionPreference = "Stop"

$wazuhVersion = "4.14.6"
$msiUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-$wazuhVersion-1.msi"
$msiPath = "$env:TEMP\wazuh-agent-$wazuhVersion.msi"

Write-Host "[*] Downloading Wazuh Agent $wazuhVersion..."
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

Write-Host "[*] Installing Wazuh Agent..."
$installArgs = "/i `"$msiPath`" /qn /l*v `"$env:TEMP\wazuh-install.log`" WAZUH_MANAGER=`"$ManagerIP`" WAZUH_AGENT_NAME=`"$AgentName`" WAZUH_AGENT_GROUP=`"$AgentGroup`""
Start-Process msiexec.exe -ArgumentList $installArgs -Wait

Write-Host "[*] Configuring agent for Sysmon log collection..."
$agentConfig = "C:\Program Files (x86)\ossec-agent\ossec.conf"
$configSnippet = @"

  <!-- Sysmon Event Log Collection -->
  <localfile>
    <log_format>eventchannel</log_format>
    <location>Microsoft-Windows-Sysmon/Operational</location>
  </localfile>

  <!-- PowerShell Script Block Logging -->
  <localfile>
    <log_format>eventchannel</log_format>
    <location>Microsoft-Windows-PowerShell/Operational</location>
    <query>EventID/4103 or EventID/4104</query>
  </localfile>

  <!-- Windows Security Event Log -->
  <localfile>
    <log_format>eventchannel</log_format>
    <location>Security</location>
  </localfile>

  <!-- Windows System Event Log -->
  <localfile>
    <log_format>eventchannel</log_format>
    <location>System</location>
  </localfile>
"@

$configContent = Get-Content $agentConfig -Raw
$insertPoint = $configContent.LastIndexOf("</ossec_config>")
if ($insertPoint -gt 0) {
    $newContent = $configContent.Insert($insertPoint, $configSnippet)
    Set-Content -Path $agentConfig -Value $newContent -NoNewline
}

Write-Host "[*] Enabling PowerShell Script Block Logging..."
$psRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
if (-not (Test-Path $psRegPath)) {
    New-Item -Path $psRegPath -Force | Out-Null
}
Set-ItemProperty -Path $psRegPath -Name "EnableScriptBlockLogging" -Value 1

Write-Host "[*] Restarting Wazuh Agent service..."
Restart-Service -Name "WazuhSvc" -Force

Write-Host "[+] Wazuh Agent installed and connected to $ManagerIP"
Write-Host "[+] Sysmon + PowerShell log collection enabled"
Write-Host ""
Write-Host "[!] Verify agent registration in Wazuh Dashboard -> Agents"
