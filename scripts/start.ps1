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

Write-Host ""
Write-Host "[+] Cloud SIEM Lab is running:"
Write-Host "    Wazuh Dashboard : https://localhost"
Write-Host "    Wazuh API       : https://localhost:55000"
Write-Host "    Login           : admin / SecretPassword"
Write-Host ""
Write-Host "[!] Register agents with: .\agents\windows\install-agent.ps1 <MANAGER_IP>"
Write-Host "[!]                       .\agents\linux\install-agent.sh <MANAGER_IP>"
