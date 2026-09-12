#!/bin/bash
set -e

WAZUH_VERSION="4.14.6"
MANAGER_IP="${1:?Usage: $0 <MANAGER_IP> [AGENT_NAME] [AGENT_GROUP]}"
AGENT_NAME="${2:-$(hostname)}"
AGENT_GROUP="${3:-default}"

echo "[*] Adding Wazuh repository..."
curl -so /etc/apt/keyrings/wazuh.gpg https://packages.wazuh.com/key/GPG-KEY-WAZUH
chmod 644 /etc/apt/keyrings/wazuh.gpg

echo "deb [signed-by=/etc/apt/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" > /etc/apt/sources.list.d/wazuh.list

echo "[*] Updating package list..."
apt-get update -y

echo "[*] Installing Wazuh Agent $WAZUH_VERSION..."
WAZUH_MANAGER="$MANAGER_IP" \
WAZUH_AGENT_NAME="$AGENT_NAME" \
WAZUH_AGENT_GROUP="$AGENT_GROUP" \
apt-get install -y wazuh-agent="$WAZUH_VERSION"-1

echo "[*] Adding custom log collection for the agent..."
cat >> /var/ossec/etc/ossec.conf << 'AGENTCONFIG'

  <!-- Auth log -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/auth.log</location>
  </localfile>

  <!-- Syslog -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>

  <!-- Nginx access log (if installed) -->
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/nginx/access.log</location>
  </localfile>

  <!-- Nginx error log (if installed) -->
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/nginx/error.log</location>
  </localfile>
AGENTCONFIG

echo "[*] Enabling and starting Wazuh Agent..."
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

echo "[+] Wazuh Agent installed and connected to $MANAGER_IP"
echo "[+] Verify agent registration in Wazuh Dashboard -> Agents"
