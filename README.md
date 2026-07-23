# Cloud SIEM Lab

Wazuh SIEM (v4.14.6) deployed via Docker on Windows — ready for AWS cloud integration.

## Quick Start

```powershell
# 1. Start Docker Desktop
# 2. Clone + deploy:
git clone https://github.com/wazuh/wazuh-docker --branch v4.14.6 wazuh-docker
cd wazuh-docker/single-node
# Copy certs/ and config/ from this repo into single-node/
docker compose up -d
```

Then open **https://localhost** — login `admin` / `SecretPassword`

## Contents

| Path | Description |
|------|-------------|
| `config/` | Wazuh config files (indexer, dashboard, manager) |
| `certs/` | SSL certificates for all 3 components |
| `scripts/` | PowerShell management scripts |
| `.opencode-context.md` | Full project context for AI assistance |

## Architecture

- **wazuh.indexer** — OpenSearch database (port 9200)
- **wazuh.manager** — Threat detection engine (ports 1514-1515, 514, 55000)
- **wazuh.dashboard** — Web UI (port 443 -> 5601)

## Credentials

- Dashboard: `admin` / `SecretPassword`
- Wazuh API: `wazuh-wui` / `MyS3cr37P450r.*-`
