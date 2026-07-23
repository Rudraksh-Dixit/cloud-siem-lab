cd "D:\soc-lab\wazuh\wazuh-docker\single-node"
docker compose up -d
Write-Output "Wazuh stack started. Access dashboard at https://localhost"
Write-Output "Login: admin / SecretPassword"