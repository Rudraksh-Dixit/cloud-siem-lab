import socket
import threading

PORTS = [22, 80, 443, 3389, 8080]


def banner(port):
    return {
        22: b"SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13\r\n",
        80: b"HTTP/1.1 200 OK\r\nServer: nginx/1.24.0\r\nContent-Length: 0\r\n\r\n",
        443: b"HTTP/1.1 200 OK\r\nServer: nginx/1.24.0\r\nContent-Length: 0\r\n\r\n",
        3389: b"\x03\x00\x00\x13\x0e\xe0\x00\x00\x00\x00\x00\x01\x00\x08\x00\x03\x00\x00\x00",
        8080: b"HTTP/1.1 200 OK\r\nServer: Apache/2.4.58\r\nContent-Length: 0\r\n\r\n",
    }.get(port, b"banner\r\n")


def serve(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(("0.0.0.0", port))
    s.listen(16)
    while True:
        conn, _ = s.accept()
        try:
            conn.recv(4096)
            conn.sendall(banner(port))
        except socket.error:
            pass
        finally:
            conn.close()


for port in PORTS:
    threading.Thread(target=serve, args=(port,), daemon=True).start()

print("victim listening on", PORTS)
while True:
    pass