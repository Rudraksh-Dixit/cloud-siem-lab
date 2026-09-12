#!/bin/bash
set -e

MANAGER_IP="${1:?Usage: $0 <MANAGER_IP> [DELAY_SECONDS]}"
DELAY="${2:-2}"
LOGFILE="$(dirname "$0")/attack-log.txt"

echo "[*] Atomic Red Team - Linux Attack Simulation" | tee "$LOGFILE"
echo "[*] Target: $MANAGER_IP" | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"

# T1110.001 - SSH Brute Force
echo "[T1110.001] SSH brute force simulation..." | tee -a "$LOGFILE"
for i in $(seq 1 15); do
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o PasswordAuthentication=yes "fakeuser$i@$MANAGER_IP" 2>/dev/null || true
    echo "[T1110.001] SSH attempt $i failed (expected)" | tee -a "$LOGFILE"
    sleep "$DELAY"
done

# T1046 - Port Scan
echo "[T1046] Port scan simulation..." | tee -a "$LOGFILE"
PORTS="22 80 443 445 3306 5432 6379 8080 8443 9200 55000"
for port in $PORTS; do
    timeout 2 bash -c "echo >/dev/tcp/$MANAGER_IP/$port" 2>/dev/null && \
        echo "[T1046] Port $port OPEN" | tee -a "$LOGFILE" || \
        echo "[T1046] Port $port closed" | tee -a "$LOGFILE"
done
sleep "$DELAY"

# T1059.004 - Bash Command Execution
echo "[T1059.004] Bash command execution test..." | tee -a "$LOGFILE"
echo "[T1059.004] Executed: whoami=$(whoami)" | tee -a "$LOGFILE"
sleep "$DELAY"

# T1083 - File Discovery
echo "[T1083] File and directory discovery..." | tee -a "$LOGFILE"
find /etc -type f -name "*.conf" 2>/dev/null | head -20 | while read f; do
    echo "[T1083] Found: $f" | tee -a "$LOGFILE"
done
sleep "$DELAY"

# T1087.001 - Local Account Discovery
echo "[T1087.001] Local account discovery..." | tee -a "$LOGFILE"
cat /etc/passwd | grep -v nologin | grep -v false | awk -F: '{print "[T1087.001] User: "$1" UID: "$3" Shell: "$7}' | tee -a "$LOGFILE"
sleep "$DELAY"

# T1082 - System Information Discovery
echo "[T1082] System info discovery..." | tee -a "$LOGFILE"
echo "[T1082] Hostname: $(hostname)" | tee -a "$LOGFILE"
echo "[T1082] OS: $(uname -a)" | tee -a "$LOGFILE"
echo "[T1082] Uptime: $(uptime)" | tee -a "$LOGFILE"
sleep "$DELAY"

# T1018 - Remote System Discovery
echo "[T1018] Remote system discovery (ARP)..." | tee -a "$LOGFILE"
arp -a 2>/dev/null | awk '{print "[T1018] Host: "$1" MAC: "$3}' | tee -a "$LOGFILE" || true

echo "" | tee -a "$LOGFILE"
echo "[+] Attack simulation complete. Check Wazuh Dashboard for alerts." | tee -a "$LOGFILE"
echo "[+] Log saved to: $LOGFILE"
