#!/usr/bin/env python3
"""Classify working-tree changes for automatic or approval-required Git sync."""
from __future__ import annotations

import argparse
import fnmatch
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POLICY_PATH = ROOT / "config" / "sync-policy.json"


def changed_paths() -> list[str]:
    output = subprocess.check_output(["git", "status", "--porcelain=v1", "--untracked-files=all"], cwd=ROOT, text=True)
    result: list[str] = []
    for line in output.splitlines():
        if len(line) < 4:
            continue
        path = line[3:]
        if " -> " in path:
            path = path.split(" -> ", 1)[1]
        if path.startswith('"') and path.endswith('"'):
            path = bytes(path[1:-1], "utf-8").decode("unicode_escape")
        result.append(path)
    return sorted(set(result))


def matches(path: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatch(path, pattern) for pattern in patterns)


def classify(paths: list[str], policy: dict) -> dict[str, list[str]]:
    result = {"allowed": [], "protected": [], "forbidden": [], "unclassified": []}
    for path in paths:
        if matches(path, policy["forbidden_paths"]):
            result["forbidden"].append(path)
        elif matches(path, policy["protected_paths"]):
            result["protected"].append(path)
        elif matches(path, policy["auto_commit_allowed"]):
            result["allowed"].append(path)
        else:
            result["unclassified"].append(path)
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    parser.add_argument("paths", nargs="*")
    args = parser.parse_args()
    policy = json.loads(POLICY_PATH.read_text(encoding="utf-8"))
    paths = args.paths or changed_paths()
    result = classify(paths, policy)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        for kind in ("forbidden", "protected", "unclassified", "allowed"):
            if result[kind]:
                print(f"{kind.upper()}:")
                for path in result[kind]:
                    print(f"  {path}")
    if result["forbidden"]:
        return 30
    if result["protected"]:
        return 20
    if result["unclassified"]:
        return 10
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
