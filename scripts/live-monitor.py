import argparse
import json
import ssl
import subprocess
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone

C = lambda n, s: f"\x1b[{n}m{s}\x1b[0m" if COLOR else s
RED, YELLOW, GREEN, CYAN, BOLD, DIM = "91", "93", "92", "96", "1", "2"

GROUP_LABELS = [("cloudtrail", "CLOUDTRAIL"), ("vpc", "VPCFLOW"), ("amazon", "CLOUDTRAIL"),
                ("suricata", "SURICATA"), ("ids", "IDS"), ("sysmon", "SYSLOG"),
                ("wazuh", "WAZUH"), ("authentication", "AUTH")]


def cat_of(groups):
    for g in groups:
        gl = g.lower()
        for frag, label in GROUP_LABELS:
            if frag in gl:
                return label
    return (groups[0][:10].upper() if groups else "?")


class Indexer:
    def __init__(self, host, user, password, exec_cmd=None):
        self.base = host
        self.ctx = ssl._create_unverified_context()
        self.auth = "Basic " + __import__("base64").b64encode(
            f"{user}:{password}".encode()).decode()
        self.exec_cmd = exec_cmd

    def _req(self, method, path, body=None):
        if self.exec_cmd:
            payload = json.dumps(body) if body is not None else ""
            url = self.base + path
            r = subprocess.run(
                [*self.exec_cmd, "curl", "-sk", "-u", "admin:SecretPassword",
                 "-H", "Content-Type: application/json", "-X", method,
                 "--data-binary", payload, url],
                capture_output=True, text=True, timeout=60)
            if r.returncode != 0:
                raise OSError(f"docker exec failed: {r.stderr[:300]}")
            return json.loads(r.stdout or "{}")
        req = urllib.request.Request(self.base + path, method=method)
        req.add_header("Authorization", self.auth)
        if body is not None:
            req.add_header("Content-Type", "application/json")
            req.data = json.dumps(body).encode()
        try:
            with urllib.request.urlopen(req, context=self.ctx, timeout=20) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            print(f"indexer error {e.code}: {e.read().decode()[:300]}", file=sys.stderr)
            raise

    def sort_field(self):
        try:
            self._req("GET", f"/{INDEX}/_mapping/field/timestamp")
            return "timestamp"
        except Exception:
            return "@timestamp"


def search(ix, field, after=None, start=None, size=1000, aggs=None):
    sort = [{field: "asc"}, {"_id": "asc"}]
    filters = []
    if start:
        filters.append({"range": {field: {"gt": int(start)}}})
    query = {"bool": {"filter": filters}} if filters else {"match_all": {}}
    body = {"size": size, "sort": sort, "query": query}
    if after:
        body["search_after"] = after
    if aggs:
        body["aggs"] = aggs
    return ix._req("GET", f"/{INDEX}/_search", body)


def alert_line(h):
    src = h["_source"]
    rule = src.get("rule", {})
    lvl = rule.get("level", 0)
    color = RED if lvl >= 8 else (YELLOW if lvl >= 5 else GREEN)
    ts = src.get("timestamp", "")[11:19]
    agent = (src.get("agent", {}) or {}).get("name", "?")
    cat = cat_of(rule.get("groups", []))
    desc = rule.get("description", "?")[:78]
    rid = rule.get("id", "?")
    return f"[{ts}] {C(color, f'lev={lvl:<2}')} {C(CYAN, rid)} {C(BOLD, desc)} {C(DIM, f'| {agent}')} {C(CYAN, cat)}"


def fetch_window(ix, field, start, after=None):
    hits = []
    while True:
        res = search(ix, field, after=after, start=start)
        page = res["hits"]["hits"]
        if not page:
            break
        hits.extend(page)
        after = page[-1]["sort"]
        if len(page) < 1000:
            break
    return hits, after


def once(ix, field, lookback):
    start = (datetime.now(timezone.utc).timestamp() - lookback) * 1000
    hits, _ = fetch_window(ix, field, start)
    srcs = [h["_source"] for h in hits]
    print(f"\n{C(BOLD, 'SOC-LAB MONITOR')} - {len(srcs)} alerts in last {int(lookback / 60)}m")
    from collections import Counter
    by_cat = Counter(cat_of(s.get("rule", {}).get("groups", [])) for s in srcs)
    by_rule = Counter((s.get("rule", {}).get("id"), s.get("rule", {}).get("description"))
                      for s in srcs)
    by_agent = Counter((s.get("agent", {}) or {}).get("name") for s in srcs)
    lvls = Counter(s.get("rule", {}).get("level", 0) for s in srcs)
    print(f"\n{C(BOLD, 'by category:')} " + "  ".join(f"{k}={v}" for k, v in by_cat.most_common()))
    print(f"{C(BOLD, 'by level:    ')} " + "  ".join(f"lvl{k}={v}" for k, v in sorted(lvls.items(), reverse=True)))
    print(f"{C(BOLD, 'by agent:    ')} " + "  ".join(f"{k}={v}" for k, v in by_agent.most_common()))
    print(f"\n{C(BOLD, 'top rules:')}")
    for (rid, desc), n in by_rule.most_common(10):
        print(f"  {C(CYAN, rid):<8} x{n:<4} {desc}")
    print(f"\n{C(BOLD, 'last 8 alerts:')}")
    for h in hits[-8:]:
        print("  " + alert_line(h))


def stream(ix, field, tail):
    start = (datetime.now(timezone.utc).timestamp() - tail) * 1000
    hits, after = fetch_window(ix, field, start)
    for h in hits:
        print(alert_line(h))
    seen = len(hits)
    t0 = time.time()
    win = []
    from collections import Counter
    counts = Counter()
    while True:
        try:
            new, after = fetch_window(ix, field, start, after=after)
        except Exception:
            time.sleep(5)
            continue
        for h in new:
            print(alert_line(h))
            counts[(h["_source"].get("rule", {}).get("groups") or ["?"])[0]] += 1
            win.append(time.time())
        seen += len(new)
        now = time.time()
        win = [t for t in win if now - t <= 60]
        if now - t0 >= 15:
            n = len(win)
            rate = f"{n / 60 * 60:.0f}/min" if n else "0/min"
            print(C(DIM, f"  -- {seen} total | {rate} | feed: {', '.join(f'{k}={v}' for k, v in counts.most_common(5))} --"))
            t0 = now
        time.sleep(INTERVAL)


def main():
    global COLOR, INDEX, INTERVAL
    ap = argparse.ArgumentParser(description="Live SOC-LAB alert monitor (indexer feed)")
    ap.add_argument("--host", default="https://wazuh.indexer:9200")
    ap.add_argument("--exec-container", default="single-node-wazuh.manager-1",
                    help="route through docker exec into this container")
    ap.add_argument("--user", default="admin")
    ap.add_argument("--password", default="SecretPassword")
    ap.add_argument("--index", default="wazuh-alerts-*")
    ap.add_argument("--once", action="store_true", help="print summary dashboard and exit")
    ap.add_argument("--lookback", type=int, default=900, help="seconds to scan back (once)")
    ap.add_argument("--tail", type=int, default=300, help="seconds to replay at start (stream)")
    ap.add_argument("--interval", type=float, default=3.0)
    args = ap.parse_args()
    INDEX, INTERVAL = args.index, args.interval
    COLOR = sys.stdout.isatty()
    ix = Indexer(args.host, args.user, args.password,
                 ["docker", "exec", "-i", args.exec_container] if args.exec_container else None)
    field = ix.sort_field()
    print(f"feed: {args.host}/{INDEX} field={field} exec={args.exec_container or 'direct'}", file=sys.stderr)
    if args.once:
        once(ix, field, args.lookback)
    else:
        stream(ix, field, args.tail)


if __name__ == "__main__":
    main()