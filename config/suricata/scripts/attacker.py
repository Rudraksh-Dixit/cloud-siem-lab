import socket
import sys
import time

VICTIM = "suricata-victim"
PORTS = [22, 80, 443, 3389, 8080, 23, 25, 53, 445, 3306, 5432, 6379, 9200]
TIMEOUT = 0.5
ROUNDS = 8


def scan(port):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(TIMEOUT)
        s.connect((VICTIM, port))
        s.close()
        return True
    except socket.error:
        return False


for r in range(ROUNDS):
    open_ports = []
    for p in PORTS:
        if scan(p):
            open_ports.append(p)
    print(f"round {r}: open={open_ports}", flush=True)
    time.sleep(0.1)

print("scan done", flush=True)
sys.exit(0)