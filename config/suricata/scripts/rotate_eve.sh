#!/bin/sh
while true; do
    sleep 60
    if [ -f /var/log/suricata/eve.json ]; then
        mv -f /var/log/suricata/eve.json /var/log/suricata/eve.json.prev
    fi
    kill -USR2 1 2>/dev/null
done