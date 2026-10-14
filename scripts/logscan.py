#!/usr/bin/env python3
"""logscan.py: summarize a service log (journalctl output or a log file).

Usage:
  journalctl -u sshd --no-pager -o short-iso | python3 logscan.py
  python3 logscan.py /var/log/secure            # Rocky / RHEL auth log
  python3 logscan.py /var/log/auth.log          # Ubuntu / Debian auth log
  journalctl -u backup.service -o short-iso --no-pager | python3 logscan.py

Prints: line count and time span, accepted logins (user, source), failed
attempts by source, and every distinct error/warning line with its count.
Standard library only.
"""
import re
import sys
from collections import Counter

# Patterns worth counting. Each is (label, compiled regex). Order matters for
# first-match classification of a line.
PATTERNS = [
    ("accepted login",    re.compile(r"Accepted (\w+) for (\S+) from (\S+)")),
    ("failed password",   re.compile(r"Failed password for (?:invalid user )?(\S+) from (\S+)")),
    ("invalid user",      re.compile(r"Invalid user (\S+) from (\S+)")),
    ("bind failed",       re.compile(r"Bind to port (\d+) .* failed: (.+)")),
    ("config error",      re.compile(r"Badly formatted|Bad configuration option|\.conf line \d+:")),
    ("bad key perms",     re.compile(r"bad permissions|are too open")),
    ("permission denied", re.compile(r"Permission denied")),
    ("connection closed", re.compile(r"Connection (?:closed|reset) by (\S+)")),
    ("no space",          re.compile(r"No space left on device")),
    ("rsync error",       re.compile(r"rsync error: (.+?) \(code (\d+)\)")),
    ("job start",         re.compile(r"backup: start")),
    ("job ok",            re.compile(r"backup: ok")),
    ("job abort",         re.compile(r"backup: ABORT")),
    ("service failed",    re.compile(r"Failed (?:to start|with result)")),
    ("error (other)",     re.compile(r"\berror\b", re.I)),
    ("warning (other)",   re.compile(r"\bwarning\b", re.I)),
]
# Timestamp at the start of a line: ISO (journalctl -o short-iso) or syslog style.
TS = re.compile(r"^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\S*|[A-Z][a-z]{2} {1,2}\d{1,2} \d{2}:\d{2}:\d{2})")

def main():
    src = open(sys.argv[1], errors="replace") if len(sys.argv) > 1 else sys.stdin
    lines = [l.rstrip("\n") for l in src]
    if not lines:
        print("no input"); return
    stamps = [m.group(1) for l in lines if (m := TS.match(l))]
    kinds, logins, failed_src, errors = Counter(), Counter(), Counter(), Counter()
    for l in lines:
        for label, rx in PATTERNS:
            m = rx.search(l)
            if not m:
                continue
            kinds[label] += 1
            if label == "accepted login":
                logins[(m.group(2), m.group(3), m.group(1))] += 1
            elif label in ("failed password", "invalid user"):
                failed_src[m.group(2)] += 1
            elif label not in ("job start", "job ok", "connection closed"):
                # strip the timestamp/host prefix so identical messages group together
                msg = re.sub(r"^.*?\]: ", "", l) if "]: " in l else l
                errors[(label, msg[:110])] += 1
            break
    print(f"lines: {len(lines)}")
    if stamps:
        print(f"span:  {stamps[0]}  ->  {stamps[-1]}")
    print("\nby kind:")
    for k, n in kinds.most_common():
        print(f"  {n:6d}  {k}")
    if logins:
        print("\naccepted logins (user, from, method):")
        for (u, s, m), n in logins.most_common():
            print(f"  {n:6d}  {u:<10} {s:<16} {m}")
    if failed_src:
        print("\nfailed attempts by source:")
        for s, n in failed_src.most_common(10):
            print(f"  {n:6d}  {s}")
    if errors:
        print("\nerrors and warnings (distinct):")
        for (label, msg), n in errors.most_common(20):
            print(f"  {n:6d}  [{label}] {msg}")

if __name__ == "__main__":
    main()
