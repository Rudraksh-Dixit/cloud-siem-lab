param(
    [string]$ComposeDir = ".\wazuh\wazuh-docker\single-node"
)

Write-Host "=== Wazuh Stack ==="
Push-Location $ComposeDir
docker compose ps
Pop-Location

Write-Host ""
Write-Host "=== Suricata + Filebeat ==="
docker compose -f .\config\suricata\docker-compose.yml ps

Write-Host ""
Write-Host "=== Grafana + DVWA ==="
docker compose -f .\docker-compose.yml ps

Write-Host ""
Write-Host "=== Wazuh Agents ==="
docker exec wazuh.manager /var/ossec/bin/agent_control -l 2>$null
