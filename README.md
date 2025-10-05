# VsDiskHastanesi

Initial repository bootstrap.

Includes:
- External update sequence script with multi-fallback fetch logic (`scripts/external-update-sequence.ps1`)
- Repeatable metadata key ensure script (`database/repeatable/22_EXTERNAL_VERSION_KEYS.sql`)
- Governance gate & smoke test scripts (`test/run_governance_gates.ps1`, `test/run_db_smoke.ps1`)

Conventions:
- Conventional Commits
- Idempotent SQL repeatable scripts under `database/repeatable/`
- PowerShell helper scripts for drift / sync

Next Steps:
1. Configure remote origin: `git remote add origin https://github.com/<user>/VsDiskHastanesi.git`
2. Push: `git push -u origin main`
3. (Optional) Tag baseline: `git tag -a v0.1.0 -m "Baseline" && git push origin v0.1.0`
