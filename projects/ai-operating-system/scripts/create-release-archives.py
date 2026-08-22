#!/usr/bin/env python3
"""Create reproducible-ish repository distribution archives after validation."""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tarfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT.parent
NAME = ROOT.name
EXCLUDED = {".git", ".venv", "__pycache__"}


def files():
    for path in sorted(ROOT.rglob("*")):
        if path.is_dir() or any(part in EXCLUDED for part in path.parts):
            continue
        yield path


def sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    result = subprocess.run([sys.executable, str(ROOT / "scripts" / "validate_repo.py")], cwd=ROOT)
    if result.returncode:
        return result.returncode
    zip_path = OUT / f"{NAME}.zip"
    tar_path = OUT / f"{NAME}.tar.gz"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files():
            archive.write(path, (Path(NAME) / path.relative_to(ROOT)).as_posix())
    with tarfile.open(tar_path, "w:gz") as archive:
        for path in files():
            archive.add(path, arcname=Path(NAME) / path.relative_to(ROOT), recursive=False)
    manifest = {
        "version": "1.0.0",
        "zip": {"path": str(zip_path), "sha256": sha(zip_path), "bytes": zip_path.stat().st_size},
        "tar_gz": {"path": str(tar_path), "sha256": sha(tar_path), "bytes": tar_path.stat().st_size},
    }
    (OUT / f"{NAME}-DOWNLOAD_MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
