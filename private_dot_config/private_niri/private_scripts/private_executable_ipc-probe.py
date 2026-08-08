#!/usr/bin/env python3
"""Probe the niri IPC socket directly, without the niri binary.

Sends a read-only Workspaces request per attempt and classifies the outcome.
Server-side failures show up as eof: niri accepts, then closes without replying.
Usage: ipc-probe.py [attempts]
"""
import json
import os
import socket
import subprocess
import sys

pid = subprocess.run(["pgrep", "-x", "niri"], capture_output=True, text=True).stdout.split()
if not pid:
    sys.exit("niri is not running")
path = os.environ.get("NIRI_SOCKET") or f"/tmp/xdg-acid/niri.wayland-1.{pid[0]}.sock"

n = int(sys.argv[1]) if len(sys.argv) > 1 else 30
res = {"ok": 0, "eof": 0, "timeout": 0, "connect_error": 0}
for _ in range(n):
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(3)
        s.connect(path)
        s.sendall(b'"Workspaces"\n')
        data = s.recv(65536)
        if not data:
            res["eof"] += 1
        else:
            json.loads(data.decode().splitlines()[0])
            res["ok"] += 1
        s.close()
    except socket.timeout:
        res["timeout"] += 1
    except OSError:
        res["connect_error"] += 1

print(path)
print(" ".join(f"{k}={v}" for k, v in res.items()))
print("each eof should have one 'error making IPC stream async' line in ~/.local/share/niri.log")
