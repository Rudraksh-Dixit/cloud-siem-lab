# Cloud SIEM Lab

Full-stack SOC lab with Wazuh SIEM, Suricata IDS, Grafana dashboards, DVWA target, and Atomic Red Team — deployed via Docker on Windows, ready for AWS cloud integration.

## Quick Start

```powershell
# 1. Start Docker Desktop
# 2. Clone Wazuh Docker:
git clone https://github.com/wazuh/wazuh-docker --branch v4.14.6 wazuh/wazuh-docker

# 3. Start the lab:
.\scripts\start.ps1
```

| Service | URL | Credentials |
|---------|-----|-------------|
| **Wazuh Dashboard** | https://localhost | `admin` / `SecretPassword` |
| **Grafana** | http://localhost:3000 | `admin` / `SecretPassword` |
| **DVWA** | http://localhost:8080 | `admin` / `password` (setup first) |
| **Wazuh API** | https://localhost:55000 | `wazuh-wui` / `MyS3cr37P450r.*-` |

## Register Agents

### Windows (Sysmon + Wazuh Agent)
```powershell
.\agents\windows\install-sysmon.ps1
.\agents\windows\install-agent.ps1 <MANAGER_IP>
```

### Linux (Ubuntu)
```bash
sudo ./agents/linux/install-agent.sh <MANAGER_IP>
```

## Attack Simulations (Atomic Red Team)

### Windows
```powershell
.\config\atomic-red-team\windows\invoke-attacks.ps1 <TARGET_IP>
```

### Linux
```bash
sudo ./config/atomic-red-team/linux/invoke-attacks.sh <MANAGER_IP>
```

### Techniques Executed

| Technique | Name | Platform |
|-----------|------|----------|
| T1059.001 | PowerShell encoded commands, IEX, download cradles | Windows |
| T1027 | Obfuscated commands (string reversal) | Windows |
| T1110.001 | SSH brute force simulation | Windows/Linux |
| T1046 | Port scan | Windows |
| T1547.001 | Registry Run key persistence | Windows |
| T1059.004 | Bash command execution | Linux |
| T1083 | File and directory discovery | Linux |
| T1087.001 | Local account discovery | Linux |
| T1082 | System information discovery | Linux |
| T1018 | Remote system discovery | Linux |

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Docker Network                    │
│                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  Wazuh   │  │  Wazuh   │  │     Wazuh       │  │
│  │ Indexer  │◄─┤ Manager  │◄─┤    Dashboard     │  │
│  │ :9200    │  │ :1514    │  │    :443          │  │
│  └────▲─────┘  └────▲─────┘  └──────────────────┘  │
│       │             │                                │
│       │        ┌────┴─────┐                         │
│       │        │ Suricata │  ┌──────────────────┐   │
│       │        │ +Filebeat│  │     Grafana      │   │
│       │        └──────────┘  │    :3000         │   │
│       │                      └──────────────────┘   │
│       │                                             │
│  ┌────┴──────────────────────────────────────────┐ │
│  │              OpenSearch Indices                │ │
│  │    wazuh-alerts-*    suricata-*               │ │
│  └───────────────────────────────────────────────┘ │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │              Attack Targets                   │  │
│  │   DVWA (:8080)  │  Victim Container          │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
        ▲                    ▲
        │                    │
   ┌────┴─────┐        ┌────┴─────┐
   │ Windows  │        │  Linux   │
   │ +Sysmon  │        │  Agent   │
   │  Agent   │        │          │
   └──────────┘        └──────────┘
```

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

## Grafana Dashboards

Pre-provisioned dashboards auto-load on first start:

1. **Alert Overview** — Alerts over time, total counts, top blocked IPs, rule breakdown
2. **Threat Detection** — SSH brute force, port scans, PowerShell obfuscation, Suricata network alerts

Data sources auto-connected to the Wazuh indexer (OpenSearch).

## MITRE ATT&CK Coverage

Import `mitre/cloud-siem-coverage.json` into the [ATT&CK Navigator](https://mitre-attack.github.io/attack-navigator/) to visualize your detection coverage.

**Coverage:** 16 techniques across 7 tactics

## DVWA Setup

1. Open http://localhost:8080
2. Login with `admin` / `password`
3. Go to **DVWA Security** → set to **Low**
4. Go to **Setup / Reset DB** → click **Create / Reset Database**
5. Start attacking — SQL injection, XSS, command injection, etc.

## Suricata → Wazuh Pipeline

```
Suricata (eve.json) → Filebeat → Wazuh Indexer
                      ↑ also read by Wazuh Manager directly
```

## File Structure

```
cloud-siem-lab/
├── agents/
│   ├── windows/
│   │   ├── install-sysmon.ps1
│   │   └── install-agent.ps1
│   └── linux/
│       └── install-agent.sh
├── config/
│   ├── atomic-red-team/
│   │   ├── windows/invoke-attacks.ps1
│   │   └── linux/invoke-attacks.sh
│   ├── dvwa/
│   ├── filebeat/filebeat.yml
│   ├── grafana/
│   │   ├── provisioning/ (datasources + dashboard provider)
│   │   └── dashboards/
│   │       ├── alert-overview.json
│   │       └── threat-detection.json
│   ├── suricata/
│   │   ├── docker-compose.yml
│   │   ├── suricata.yaml
│   │   ├── rules/local.rules
│   │   └── scripts/
│   ├── wazuh_cluster/wazuh_manager.conf
│   ├── wazuh_dashboard/
│   ├── wazuh_indexer/
│   ├── wazuh_indexer_ssl_certs/
│   └── wazuh_rules/
│       ├── custom_rules.xml
│       └── active_response.xml
├── mitre/
│   └── cloud-siem-coverage.json
├── scripts/
│   ├── start.ps1
│   ├── stop.ps1
│   ├── status.ps1
│   ├── validate-rules.ps1
│   ├── traffic-loop.ps1
│   └── live-monitor.py
├── docker-compose.yml          # Grafana + DVWA
└── README.md
```

## Credentials

| Service | Username | Password |
|---------|----------|----------|
| Wazuh Dashboard | `admin` | `SecretPassword` |
| Wazuh API | `wazuh-wui` | `MyS3cr37P450r.*-` |
| Grafana | `admin` | `SecretPassword` |
| DVWA | `admin` | `password` |

## Roadmap

- [x] Wazuh SIEM on Docker
- [x] Suricata IDS
- [x] Windows agent with Sysmon
- [x] Linux agent
- [x] Custom detection rules (MITRE-mapped)
- [x] Active response (auto-block, kill, isolate)
- [x] Suricata → Wazuh log forwarding
- [x] Grafana dashboards
- [x] DVWA vulnerable app
- [x] Atomic Red Team attack simulation
- [x] MITRE ATT&CK Navigator coverage map
- [ ] AWS GuardDuty / CloudTrail ingestion
- [ ] TheHive / Shuffle SOAR
- [ ] Cowrie honeypot
- [ ] Terraform / Ansible IaC
