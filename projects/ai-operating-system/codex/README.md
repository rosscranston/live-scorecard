# Codex Integration

Run `scripts/install-local-skills.sh` to symlink every repository skill into `~/.agents/skills`. Codex loads user skills from that location.

Recommended workflow:

```bash
cd ~/AI/ai-operating-system
codex
```

Use `/skills` to inspect available skills or type `$work-auditor`, `$agent-architect`, or another explicit skill mention.

Because symlinks point into the Git working copy, a successful Git pull updates the files Codex sees. Restart Codex if a newly added skill does not appear.
