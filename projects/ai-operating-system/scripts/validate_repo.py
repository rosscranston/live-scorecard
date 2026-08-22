#!/usr/bin/env python3
"""Validate repository structure, skills, JSON, YAML, and explicit invocation policy."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML is required. Run a platform bootstrap script.", file=sys.stderr)
    raise SystemExit(2)

try:
    import jsonschema
except ImportError:
    jsonschema = None

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_ROOT = [
    "README.md", "INSTALLATION_GUIDE.md", "SECURITY_AND_DATA_HANDLING.md",
    "APPROVAL_POLICY.md", "AGENTS.md", "config/shared-settings.yaml",
    "config/approval-policy.yaml", "config/sync-policy.json",
    "schemas/workspace-action.schema.json"
]
NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def error(message: str, errors: list[str]) -> None:
    errors.append(message)


def frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        raise ValueError("missing YAML frontmatter")
    end = text.find("\n---\n", 4)
    if end == -1:
        raise ValueError("unterminated YAML frontmatter")
    data = yaml.safe_load(text[4:end])
    if not isinstance(data, dict):
        raise ValueError("frontmatter is not a mapping")
    return data


def main() -> int:
    errors: list[str] = []
    for rel in REQUIRED_ROOT:
        if not (ROOT / rel).exists():
            error(f"Missing required file: {rel}", errors)

    names: set[str] = set()
    skill_dirs = sorted(p for p in (ROOT / "skills").iterdir() if p.is_dir()) if (ROOT / "skills").exists() else []
    if len(skill_dirs) != 13:
        error(f"Expected 13 skills, found {len(skill_dirs)}", errors)

    for skill_dir in skill_dirs:
        skill_file = skill_dir / "SKILL.md"
        for rel in ["SKILL.md", "README.md", "CHANGELOG.md", "DECISIONS.md", "agents/openai.yaml", "tests/cases.json"]:
            if not (skill_dir / rel).exists():
                error(f"{skill_dir.name}: missing {rel}", errors)
        if not skill_file.exists():
            continue
        try:
            fm = frontmatter(skill_file)
        except Exception as exc:
            error(f"{skill_dir.name}: invalid SKILL.md: {exc}", errors)
            continue
        name = fm.get("name")
        description = fm.get("description")
        if name != skill_dir.name:
            error(f"{skill_dir.name}: frontmatter name mismatch: {name!r}", errors)
        if not isinstance(name, str) or not NAME_RE.match(name):
            error(f"{skill_dir.name}: invalid skill name", errors)
        if name in names:
            error(f"Duplicate skill name: {name}", errors)
        names.add(name)
        if not isinstance(description, str) or len(description.strip()) < 20:
            error(f"{skill_dir.name}: description is too short", errors)
        metadata = fm.get("metadata", {}) if isinstance(fm.get("metadata", {}), dict) else {}
        version = str(fm.get("version", metadata.get("version", "")))
        if version != "1.0.0":
            error(f"{skill_dir.name}: expected version 1.0.0, got {version!r}", errors)
        openai_path = skill_dir / "agents" / "openai.yaml"
        if openai_path.exists():
            try:
                openai = yaml.safe_load(openai_path.read_text(encoding="utf-8")) or {}
                if openai.get("policy", {}).get("allow_implicit_invocation") is not False:
                    error(f"{skill_dir.name}: implicit invocation must be false", errors)
            except Exception as exc:
                error(f"{skill_dir.name}: invalid agents/openai.yaml: {exc}", errors)
        tests_path = skill_dir / "tests" / "cases.json"
        if tests_path.exists():
            try:
                tests = json.loads(tests_path.read_text(encoding="utf-8"))
                kinds = {case.get("type") for case in tests.get("cases", [])}
                if not {"positive", "negative", "boundary"}.issubset(kinds):
                    error(f"{skill_dir.name}: tests need positive, negative, and boundary cases", errors)
            except Exception as exc:
                error(f"{skill_dir.name}: invalid tests JSON: {exc}", errors)

    for path in ROOT.rglob("*.json"):
        if any(part in {".git", ".venv", "dist"} for part in path.parts):
            continue
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            error(f"Invalid JSON {path.relative_to(ROOT)}: {exc}", errors)

    for path in list((ROOT / "config").glob("*.yaml")) + list((ROOT / "config").glob("*.yml")):
        try:
            yaml.safe_load(path.read_text(encoding="utf-8"))
        except Exception as exc:
            error(f"Invalid YAML {path.relative_to(ROOT)}: {exc}", errors)

    schema_dir = ROOT / "schemas"
    if jsonschema is not None and schema_dir.exists():
        for path in schema_dir.glob("*.schema.json"):
            try:
                jsonschema.Draft202012Validator.check_schema(json.loads(path.read_text(encoding="utf-8")))
            except Exception as exc:
                error(f"Invalid JSON Schema {path.name}: {exc}", errors)

    if errors:
        print("Repository validation failed:", file=sys.stderr)
        for item in errors:
            print(f"- {item}", file=sys.stderr)
        return 1
    print(f"Repository validation passed: {len(skill_dirs)} skills, {len(list(ROOT.rglob('*.json')))} JSON files.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
