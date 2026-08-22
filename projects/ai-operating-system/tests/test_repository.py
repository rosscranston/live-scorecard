from __future__ import annotations

import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RepositoryTests(unittest.TestCase):
    def test_thirteen_unique_skills(self) -> None:
        skills = [p for p in (ROOT / "skills").iterdir() if p.is_dir() and (p / "SKILL.md").exists()]
        self.assertEqual(13, len(skills))
        self.assertEqual(len(skills), len({p.name for p in skills}))

    def test_all_skills_explicit_only(self) -> None:
        import yaml
        for skill in (ROOT / "skills").iterdir():
            if not (skill / "SKILL.md").exists():
                continue
            config = yaml.safe_load((skill / "agents" / "openai.yaml").read_text())
            self.assertIs(config["policy"]["allow_implicit_invocation"], False, skill.name)

    def test_sync_never_force_pushes(self) -> None:
        script = (ROOT / "scripts" / "ai-os-sync.sh").read_text()
        self.assertNotIn("--force", script)
        self.assertNotIn("--force-with-lease", script)

    def test_github_writes_are_limited_to_primary_owner(self) -> None:
        import yaml
        shared = yaml.safe_load((ROOT / "config" / "shared-settings.yaml").read_text())
        repository = shared["repository"]
        self.assertEqual("primary_owner_only", repository["github_write_scope"])
        self.assertEqual("rosscranston", repository["primary_owner_login"])
        self.assertNotEqual("rossclo", repository["primary_owner_login"])

        approval = yaml.safe_load((ROOT / "config" / "approval-policy.yaml").read_text())
        self.assertEqual(
            "prohibited",
            approval["modes"]["github_non_primary_owner_write"]["default"],
        )
        self.assertIn("github_non_primary_owner_write", approval["permanent_no_autonomy"])

    def test_workspace_action_schema_parses(self) -> None:
        schema = json.loads((ROOT / "schemas" / "workspace-action.schema.json").read_text())
        self.assertIn("idempotency_key", schema["required"])
        self.assertIn("verification", schema["required"])

    def test_validator_passes(self) -> None:
        result = subprocess.run([sys.executable, str(ROOT / "scripts" / "validate_repo.py")], cwd=ROOT)
        self.assertEqual(0, result.returncode)


if __name__ == "__main__":
    unittest.main()
