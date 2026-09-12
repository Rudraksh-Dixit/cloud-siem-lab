# Cloud SIEM Lab

Full-stack SOC lab with Wazuh SIEM, Suricata IDS, Sysmon, and active response — deployed via Docker on Windows, ready for AWS cloud integration.

## Quick Start

```powershell
# 1. Start Docker Desktop
# 2. Clone Wazuh Docker:
git clone https://github.com/wazuh/wazuh-docker --branch v4.14.6 wazuh/wazuh-docker

# 3. Start the lab:
.\scripts\start.ps1
```

Open **https://localhost** — login `admin` / `SecretPassword`

## Register Agents

### Windows (Sysmon + Wazuh Agent)
```powershell
# Install Sysmon first:
.\agents\windows\install-sysmon.ps1

# Then the Wazuh agent:
.\agents\windows\install-agent.ps1 <MANAGER_IP>
```

### Linux (Ubuntu)
```bash
sudo ./agents/linux/install-agent.sh <MANAGER_IP>
```

## Architecture

| Component | Description | Port |
|-----------|-------------|------|
| **wazuh.indexer** | OpenSearch database | 9200 |
| **wazuh.manager** | Threat detection engine | 1514-1515, 514, 55000 |
| **wazuh.dashboard** | Web UI | 443 → 5601 |
| **suricata** | Network IDS | — |
| **filebeat** | Suricata → Wazuh log forwarder | — |

## Detection Rules

Custom rules in `config/wazuh_rules/custom_rules.xml`:

| Rule ID | Level | Detection | MITRE ATT&CK |
|---------|-------|-----------|---------------|
| 100001 | 12 | PowerShell obfuscation (IEX + encoded) | T1059.001, T1027 |
| 100002 | 14 | Base64 + compression deobfuscation | T1059.001, T1140 |
| 100003 | 10 | Execution policy bypass | T1059.001 |
| 100010 | 10 | SSH brute force (8+ in 2min) | T1110.001 |
| 100011 | 12 | SSH sustained brute force (15+ in 5min) | T1110.001 |
| 100012 | 8 | SSH invalid username attempt | T1110.001 |
| 100020 | 12 | Port scan (12+ ports in 60s) | T1046 |
| 100021 | 10 | Auth scan (multiple users, same source) | T1110.003 |
| 100030 | 12 | Office app spawning shell | T1059, T1566.001 |
| 100031 | 14 | lsass.exe spawning shell (injection) | T1055, T1003.001 |
| 100040 | 12 | Registry Run key modification | T1547.001 |
| 100041 | 10 | Remote admin tool execution | T1021.002, T1047 |

## Active Response

| Trigger | Response | Duration |
|---------|----------|----------|
| SSH brute force (100100) | `firewall-drop` | 1 hour |
| Port scan (100101) | `firewall-drop` | 30 min |
| Credential dumping (100031) | `kill-process` | Immediate |
| Credential dumping (100031) | `route-null` (isolate host) | 2 hours |

## Suricata → Wazuh Pipeline

Suricata alerts are forwarded to the Wazuh indexer via Filebeat:

```
Suricata (eve.json) → Filebeat → Wazuh Indexer
                      ↑ also read by Wazuh Manager directly
```

Filebeat config: `config/filebeat/filebeat.yml`

## File Structure

```
cloud-siem-lab/
├── agents/
│   ├── windows/
│   │   ├── install-sysmon.ps1      # Sysmon + SwiftOnSecurity config
│   │   └── install-agent.ps1       # Wazuh agent + log collection
│   └── linux/
│       └── install-agent.sh        # Wazuh agent for Ubuntu
├── config/
│   ├── suricata/
│   │   ├── docker-compose.yml      # Suricata + Filebeat stack
│   │   ├── suricata.yaml
│   │   ├── rules/local.rules
│   │   └── scripts/                # attacker.py, victim.py
│   ├── wazuh_cluster/
│   │   └── wazuh_manager.conf      # Manager config + active response
│   ├── wazuh_indexer/
│   ├── wazuh_dashboard/
│   ├── wazuh_indexer_ssl_certs/
│   ├── wazuh_rules/
│   │   ├── custom_rules.xml        # Detection rules
│   │   └── active_response.xml     # AR trigger rules
│   └── filebeat/
│       └── filebeat.yml             # Suricata → Wazuh forwarding
├── scripts/
│   ├── start.ps1
│   ├── stop.ps1
│   ├── status.ps1
│   ├── validate-rules.ps1
│   ├── traffic-loop.ps1
│   └── live-monitor.py
└── README.md
```

## Credentials

- Dashboard: `admin` / `SecretPassword`
- Wazuh API: `wazuh-wui` / `MyS3cr37P450r.*-`

## Roadmap

- [x] Wazuh SIEM on Docker
- [x] Suricata IDS
- [x] Windows agent with Sysmon
- [x] Linux agent
- [x] Custom detection rules (MITRE-mapped)
- [x] Active response (auto-block, kill, isolate)
- [x] Suricata → Wazuh log forwarding
- [ ] Vulnerable app (DVWA/Juice Shop)
- [ ] Atomic Red Team attack simulation
- [ ] MITRE ATT&CK Navigator coverage map
- [ ] AWS GuardDuty / CloudTrail ingestion
- [ ] TheHive / Shuffle SOAR
- [ ] Cowrie honeypot
- [ ] Grafana dashboards
- [ ] Terraform / Ansible IaC
