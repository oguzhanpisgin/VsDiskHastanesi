# Changelog

All notable changes to this project will be documented in this file.

Format: Keep a human concise summary per version (YYYY-MM-DD). Follow SemVer (MAJOR.MINOR.PATCH).

## [0.1.0] - 2025-10-05
### Added
- Initial database schema & repeatable scripts (00..22)
- External version metadata ensure script (22_EXTERNAL_VERSION_KEYS)
- Governance gates package (23_GOVERNANCE_GATES) with Go/No-Go report
- Consolidated version summary procedure (24_VERSION_SUMMARY)
- External fetch logging (25_EXTERNAL_FETCH_LOG) & retention (26_EXTERNAL_FETCH_RETENTION)
- External update PowerShell sequence with multi-branch fallback + PS 5.1 compatibility
- Logging to ExternalFetchLog (OK/FAIL) and retention proc `sp_PurgeExternalFetchLog`
- CI: daily external sync workflow (`external-sync.yml`)
- CI: security scan workflow (gitleaks + vulnerable package scan)

### Known / Deferred
- KeywordGap source 404 – currently skipped; manual RefDate placeholder
- No drift checker yet (planned `sp_SchemaDriftCheck`)
- Benchmark suite aggregation proc pending (`sp_RunBenchSuite`)
- External fetch health summary proc pending

### Integrity
- Governance Gate decision at baseline: GO (rules & tables synchronized, zero dynamic SQL findings)

---
Next planned version: 0.2.0 – add health & drift procedures and KeywordGap resilient source.
