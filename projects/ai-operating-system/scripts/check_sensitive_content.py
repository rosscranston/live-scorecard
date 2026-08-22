#!/usr/bin/env python3
"""Best-effort scanner for secrets and restricted identifiers before Git sync."""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAX_BYTES = 2_000_000
SKIP_DIRS = {".git", ".venv", "venv", "__pycache__", "dist", ".state", "logs"}
SKIP_EXTS = {".zip", ".gz", ".tar", ".png", ".jpg", ".jpeg", ".gif", ".pdf", ".sqlite", ".db", ".pyc"}

PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("private key", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----")),
    ("OpenAI-style secret", re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b")),
    ("GitHub token", re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}\b")),
    ("AWS access key", re.compile(r"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b")),
    ("Slack token", re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b")),
    ("generic assigned secret", re.compile(r"(?i)\b(?:api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|password)\s*[:=]\s*['\"]?(?!unset\b|replace\b|example\b|change-me\b|<)[A-Za-z0-9_./+@-]{12,}")),
    ("US Social Security number", re.compile(r"\b(?!000|666|9\d\d)\d{3}-(?!00)\d{2}-(?!0000)\d{4}\b")),
    ("possible EIN", re.compile(r"\b\d{2}-\d{7}\b")),
]

FORBIDDEN_PATH_PARTS = {
    "client-data", "raw-data", "raw-transcripts", "attachments", "exports"
}
FORBIDDEN_SUFFIXES = {".pem", ".key", ".p12", ".pfx"}


def run_git(args: list[str]) -> bytes:
    return subprocess.check_output(["git", *args], cwd=ROOT, stderr=subprocess.DEVNULL)


def git_paths(mode: str) -> list[Path]:
    try:
        if mode == "staged":
            raw = run_git(["diff", "--cached", "--name-only", "--diff-filter=ACMR", "-z"])
        elif mode == "tracked":
            raw = run_git(["ls-files", "-z"])
        else:
            raise ValueError(mode)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    return [ROOT / p.decode("utf-8", "surrogateescape") for p in raw.split(b"\0") if p]


def all_files() -> list[Path]:
    result: list[Path] = []
    for base, dirs, files in os.walk(ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for name in files:
            result.append(Path(base) / name)
    return result


def forbidden_path(path: Path) -> str | None:
    try:
        rel = path.relative_to(ROOT)
    except ValueError:
        return "outside repository"
    if any(part in FORBIDDEN_PATH_PARTS for part in rel.parts):
        return "forbidden restricted-data directory"
    if path.suffix.lower() in FORBIDDEN_SUFFIXES:
        return "forbidden credential/key suffix"
    if path.name in {".env", "secrets.env", "local-settings.yaml", "connectors.yaml"}:
        return "forbidden local secret/config filename"
    return None


def scan(path: Path) -> list[tuple[int, str, str]]:
    findings: list[tuple[int, str, str]] = []
    reason = forbidden_path(path)
    if reason:
        return [(0, reason, path.name)]
    if not path.is_file() or path.suffix.lower() in SKIP_EXTS:
        return findings
    try:
        if path.stat().st_size > MAX_BYTES:
            return findings
        data = path.read_bytes()
    except OSError:
        return findings
    if b"\x00" in data[:4096]:
        return findings
    text = data.decode("utf-8", "replace")
    for lineno, line in enumerate(text.splitlines(), 1):
        if "sensitive-scan: allow" in line:
            continue
        for label, pattern in PATTERNS:
            match = pattern.search(line)
            if match:
                excerpt = line[max(0, match.start() - 18): match.end() + 18]
                excerpt = re.sub(r"[A-Za-z0-9]", "*", excerpt)
                findings.append((lineno, label, excerpt[:120]))
    return findings


def main() -> int:
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--staged", action="store_true")
    group.add_argument("--all-tracked", action="store_true")
    group.add_argument("--all-files", action="store_true")
    args = parser.parse_args()

    if args.staged:
        paths = git_paths("staged")
    elif args.all_tracked:
        paths = git_paths("tracked")
    else:
        paths = all_files()

    total = 0
    for path in sorted(set(paths)):
        for line, label, excerpt in scan(path):
            rel = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
            print(f"BLOCK: {rel}:{line}: {label}: {excerpt}", file=sys.stderr)
            total += 1
    if total:
        print(f"Sensitive-content scan blocked {total} finding(s). Review and remove or explicitly sanitize the content.", file=sys.stderr)
        return 1
    print(f"Sensitive-content scan passed ({len(paths)} files checked).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
