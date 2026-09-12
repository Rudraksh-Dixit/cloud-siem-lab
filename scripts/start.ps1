param(
    [string]$ComposeDir = ".\wazuh\wazuh-docker\single-node"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not running. Start Docker Desktop first."
    exit 1
}

Write-Host "[*] Starting Wazuh stack..."
Push-Location $ComposeDir
docker compose up -d
Pop-Location

Write-Host "[*] Starting Suricata + Filebeat..."
docker compose -f .\config\suricata\docker-compose.yml up -d

Write-Host "[*] Starting Grafana + DVWA..."
docker compose -f .\docker-compose.yml up -d

Write-Host ""
Write-Host "[+] Cloud SIEM Lab is running:"
Write-Host "    Wazuh Dashboard : https://localhost"
Write-Host "    Grafana         : http://localhost:3000"
Write-Host "    DVWA            : http://localhost:8080"
Write-Host "    Wazuh API       : https://localhost:55000"
Write-Host ""
Write-Host "    Login (all)     : admin / SecretPassword"
Write-Host ""
Write-Host "[!] Register agents:"
Write-Host "    .\agents\windows\install-sysmon.ps1; .\agents\windows\install-agent.ps1 <IP>"
Write-Host "    sudo ./agents/linux/install-agent.sh <IP>"
Write-Host ""
Write-Host "[!] Run attack simulations:"
Write-Host "    .\config\atomic-red-team\windows\invoke-attacks.ps1 <TARGET>"
Write-Host "    sudo ./config/atomic-red-team/linux/invoke-attacks.sh <IP>"
