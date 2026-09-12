param(
    [string]$ComposeDir = ".\wazuh\wazuh-docker\single-node"
)

Write-Host "[*] Stopping Grafana + DVWA..."
docker compose -f .\docker-compose.yml down

Write-Host "[*] Stopping Suricata + Filebeat..."
docker compose -f .\config\suricata\docker-compose.yml down

Write-Host "[*] Stopping Wazuh stack..."
Push-Location $ComposeDir
docker compose down
Pop-Location

Write-Host "[+] Cloud SIEM Lab stopped"
