#!/usr/bin/env python3
"""Build upload-ready ZIP files for every portable skill."""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
import zipfile
from hashlib import sha256
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist" / "chatgpt-skills"
VERSION = "1.0.0"
SKIP_NAMES = {".DS_Store", "__pycache__"}


def zip_skill(skill_dir: Path, destination: Path) -> None:
    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in sorted(skill_dir.rglob("*")):
            if path.is_dir() or any(part in SKIP_NAMES for part in path.parts):
                continue
            arcname = Path(skill_dir.name) / path.relative_to(skill_dir)
            archive.write(path, arcname.as_posix())


def digest(path: Path) -> str:
    h = sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    validator = ROOT / "scripts" / "validate_repo.py"
    result = subprocess.run([sys.executable, str(validator)], cwd=ROOT)
    if result.returncode:
        return result.returncode
    if DIST.parent.exists():
        shutil.rmtree(DIST.parent)
    DIST.mkdir(parents=True)
    manifest = {"version": VERSION, "skills": []}
    skill_dirs = sorted(p for p in (ROOT / "skills").iterdir() if p.is_dir() and (p / "SKILL.md").exists())
    for skill_dir in skill_dirs:
        out = DIST / f"{skill_dir.name}-{VERSION}.zip"
        zip_skill(skill_dir, out)
        manifest["skills"].append({"name": skill_dir.name, "file": out.name, "sha256": digest(out), "bytes": out.stat().st_size})
        print(f"Built {out.relative_to(ROOT)}")

    all_out = ROOT / "dist" / f"chatgpt-skills-all-{VERSION}.zip"
    with zipfile.ZipFile(all_out, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for skill_dir in skill_dirs:
            for path in sorted(skill_dir.rglob("*")):
                if path.is_dir() or any(part in SKIP_NAMES for part in path.parts):
                    continue
                archive.write(path, (Path("skills") / skill_dir.name / path.relative_to(skill_dir)).as_posix())
    manifest["all_bundle"] = {"file": all_out.name, "sha256": digest(all_out), "bytes": all_out.stat().st_size}
    manifest_path = ROOT / "dist" / "skill-manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"Built {all_out.relative_to(ROOT)}")
    print(f"Manifest: {manifest_path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
