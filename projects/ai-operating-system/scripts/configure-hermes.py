#!/usr/bin/env python3
"""Safely add this repository's skill directory to Hermes config."""
from __future__ import annotations

import argparse
import shutil
import sys
from datetime import datetime
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML is required. Run the platform bootstrap script.", file=sys.stderr)
    raise SystemExit(2)


def load_yaml(path: Path) -> dict:
    if not path.exists() or not path.read_text(encoding="utf-8").strip():
        return {}
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if data is None:
        return {}
    if not isinstance(data, dict):
        raise ValueError(f"Expected a mapping in {path}")
    return data


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true", help="Back up and update Hermes config")
    mode.add_argument("--check", action="store_true", help="Check whether Hermes is configured")
    parser.add_argument("--config", type=Path, default=Path.home() / ".hermes" / "config.yaml")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()

    repo = args.repo.expanduser().resolve()
    skills_dir = (repo / "skills").resolve()
    if not skills_dir.is_dir():
        print(f"Skills directory not found: {skills_dir}", file=sys.stderr)
        return 2

    config_path = args.config.expanduser()
    config = load_yaml(config_path)
    skills = config.setdefault("skills", {})
    if not isinstance(skills, dict):
        print("Hermes config key 'skills' is not a mapping; refusing to overwrite it.", file=sys.stderr)
        return 3
    external = skills.setdefault("external_dirs", [])
    if not isinstance(external, list):
        print("Hermes config key 'skills.external_dirs' is not a list; refusing to overwrite it.", file=sys.stderr)
        return 3

    normalized = [str(Path(str(p)).expanduser().resolve()) for p in external]
    configured = str(skills_dir) in normalized
    approval = skills.get("write_approval") is True

    if args.check:
        print(f"Config: {config_path}")
        print(f"External skill directory configured: {configured}")
        print(f"Skill write approval enabled: {approval}")
        return 0 if configured and approval else 1

    if not configured:
        external.append(str(skills_dir))
    skills["write_approval"] = True
    config_path.parent.mkdir(parents=True, exist_ok=True)
    if config_path.exists():
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = config_path.with_name(config_path.name + f".backup-{stamp}")
        shutil.copy2(config_path, backup)
        print(f"Backup: {backup}")
    config_path.write_text(yaml.safe_dump(config, sort_keys=False, allow_unicode=True), encoding="utf-8")
    print(f"Updated: {config_path}")
    print(f"Hermes external skills: {skills_dir}")
    print("Hermes skill writes now require approval.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
