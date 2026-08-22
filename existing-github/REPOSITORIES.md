# Canonical repositories and dependencies

Use one checkout per computer and let Git synchronize source code. Do not synchronize a working directory with cloud-drive file mirroring.

## Ross-owned canonical repositories

```bash
git clone git@github.com:rosscranston/ai-operating-system.git
git clone git@github.com:rosscranston/private-notes.git
```

The migration bundle also contains source snapshots so the uncommitted Hermes state is not lost. Compare those snapshots with the fresh clones before replacing files.

## Read-only or separately owned dependencies

```bash
git clone git@github.com:CranstonAI/cranston-growth.git
git clone https://github.com/rossmusic/tier-1-vc-jobs.git head-of-growth-series-a-or-b
```

The current AI Operating System policy permits GitHub writes only to repositories owned by `rosscranston`. The sources above were therefore not republished into a new owner namespace.

