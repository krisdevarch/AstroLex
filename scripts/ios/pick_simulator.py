#!/usr/bin/env python3
"""Prints the UDID of an available iPhone simulator for `xcodebuild -destination id=<udid>`.

Picks SIM_DEVICE by exact name if set; otherwise an iPhone "Pro" (not Max) on the newest
iOS runtime, falling back to any iPhone. Reads `xcrun simctl list devices available -j`
from stdin when piped (used by the tests), else runs it. Python 3.9+, stdlib only.
"""
import json
import os
import re
import subprocess
import sys


def runtime_version(key):
    # com.apple.CoreSimulator.SimRuntime.iOS-26-2 -> (26, 2)
    m = re.search(r"\.iOS-(\d+(?:-\d+)*)$", key)
    return tuple(int(p) for p in m.group(1).split("-")) if m else None


def pick(devices_json, wanted=None):
    candidates = []
    for runtime, devices in devices_json.get("devices", {}).items():
        version = runtime_version(runtime)
        if version is None:
            continue
        for d in devices:
            if d.get("isAvailable", True) and d.get("name", "").startswith("iPhone"):
                candidates.append((version, d["name"], d["udid"]))
    if wanted:
        named = [c for c in candidates if c[1] == wanted]
        if not named:
            return None
        return max(named)[2]
    if not candidates:
        return None

    def score(c):
        version, name, _ = c
        return (version, "Pro" in name and "Max" not in name, name)

    return max(candidates, key=score)[2]


def main():
    if sys.stdin.isatty():
        raw = subprocess.run(["xcrun", "simctl", "list", "devices", "available", "-j"],
                             check=True, stdout=subprocess.PIPE).stdout
    else:
        raw = sys.stdin.read()
    udid = pick(json.loads(raw), os.environ.get("SIM_DEVICE") or None)
    if not udid:
        want = os.environ.get("SIM_DEVICE")
        print("No iPhone simulator found%s. Install one in Xcode > Settings > Components."
              % (" named %r" % want if want else ""), file=sys.stderr)
        return 1
    print(udid)
    return 0


if __name__ == "__main__":
    sys.exit(main())
