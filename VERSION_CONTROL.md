# Version Control Strategy for SBOMBS Packages

This document explains how version numbers are managed for the SBOMBS packages published to PyPI and npm, and how Git is used to audit and track deployments.

## Overview

**Key principle:** Package versions are managed according to package type:
- **Daily packages:** Versions are **computed at CI runtime** (date-based) and **not committed to source**
- **Yearly packages:** Versions are **committed to source** (semantic versioning) with **explicit, manual publishing**

Both are tracked via **Git tags** that point to the exact source code that was built and published.

This strategy:
- ✅ Prevents version-number merge conflicts in daily source (versions computed at CI time)
- ✅ Allows deterministic, automated versioning (e.g., daily dates for daily packages)
- ✅ Protects yearly packages via semantic versioning and manual approval workflow
- ✅ Creates an immutable audit trail in Git history
- ✅ Enables forensic debugging: "What code was released as version X.Y.Z?"

## Versioning Scheme

### Daily Package (`sbombs-daily` / `@sbombs/daily`)

- **Version format:** `YYYY.M.D` (calendar versioning, UTC date, no leading zeros)
  - Example: `2026.9.29` (September 29, 2026)
- **Computation:** CI computes version at publish time: `date -u +'%Y.%-m.%-d'` (UTC)
- **Release frequency:** Daily at 06:00 UTC via scheduled workflow
- **Source config:** `package.json` and `pyproject.toml` always contain `"version": "0.0.0"` (static placeholder)
- **Rationale:** Daily packages must have a version of every age. Each UTC calendar day generates a unique, immutable version.

### Yearly Package (`sbombs-yearly` / `@sbombs/yearly`)

- **Version format:** Semantic versioning with year in major: `YYYY.M.0`
  - Example: `2026.1.0` (first yearly release of 2026), `2027.1.0` (first yearly release of 2027)
  - If multiple releases needed in one year: `2026.2.0`, `2026.3.0`, etc.
- **Release frequency:** **Once per year** (or on-demand, with explicit confirmation)
- **Source config:** `package.json` and `pyproject.toml` contain the semantic version (not `0.0.0`)
- **Rationale:** Yearly package is a control/baseline. Its immutable release must always pass immaturity policies. Semantic versioning makes the age (year) self-documenting.

## Git Tagging Strategy

Every successful publish to PyPI or npm creates a **Git tag** pointing to the exact commit that was built.

### Tag Naming Convention

- **Daily:** `daily@YYYY.M.D`
  - Example: `daily@2026.9.29`
  - New tag created every day

- **Yearly:** `yearly@YYYY.M.0`
  - Example: `yearly@2026.1.0`
  - Created once per year (or on-demand, but never overwritten)

### How Tags Are Created

1. CI workflow builds the package from source
2. Package is published to PyPI/npm
3. After successful publish, CI workflow runs:
   ```bash
   # Daily
   git tag -a "daily@$(date -u +'%Y.%-m.%-d')" \
     -m "Published daily v$(date -u +'%Y.%-m.%-d')" \
     HEAD
   git push origin <tag>
   
   # Yearly
   git tag -a "yearly@${VERSION}" \
     -m "Published yearly v${VERSION} (yearly control package)" \
     HEAD
   git push origin <tag>
   ```
4. A GitHub Release is created (optional, for visibility in the web UI)

### Why Tags Matter

Tags are the **primary audit trail**:

- `git show daily@2026.9.29` → See the exact source code published on that date
- `git show yearly@2026.1.0` → See the exact source code published for that year's release
- `git tag -l` → List all published versions (view full release history)
- `git log --oneline --decorate` → See release points in the commit history
- Cannot be accidentally deleted (require force push, which is blocked on `main`)

## Branch Protection & Immutability

### Yearly Package Protection

Files under `canaries/npm/yearly/` and `canaries/pypi/sbombs-yearly/` are protected by GitHub branch protection rules:

1. **All direct pushes to `main` are blocked** for these paths
2. **Pull requests are required** for any changes
3. **Code owner approval is required** (assigned to `@sbombs/maintainers` in `.github/CODEOWNERS`)
4. **Stale reviews are dismissed** to prevent old approvals from being reused

**Why?** The yearly control package must never be modified after publication. Any change would corrupt the test baseline.

The yearly publishing workflow (`yearly.yml`) includes additional safety checks:
- Verification that the version has not already been published (prevents accidental republishing)
- Explicit maintainer confirmation required (must type "yes" to trigger publish)
- Safety checks ensure immutability guarantees

### Daily Package Protection

Files under `canaries/npm/daily/` and `canaries/pypi/sbombs-daily/` require maintainer review to ensure:
- No install scripts or runtime dependencies are introduced
- Package remains inert and suitable for repeated publication
- Version string remains `0.0.0` in source (CI will compute real version on each publish)
- No changes that would break the automation or compromise data quality

## Local Development: Pre-Commit Hook (Optional)

A local pre-commit hook can warn developers if they attempt to edit the anchor packages:

```bash
# Install the hook (from repo root)
mkdir -p .git-hooks
# See .git-hooks/pre-commit (if present)
git config core.hooksPath .git-hooks
```

This is **optional friction**, not a blocker. The GitHub branch protection rule is the real safeguard.

## CI Workflows

### `daily.yml`

- **Trigger:** Schedule (06:00 UTC daily) or manual dispatch
- **Steps:**
  1. Check out code
  2. Compute version as `date -u +'%Y.%-m.%-d'`
  3. Build `sbombs-daily` (PyPI wheel + sdist)
  4. Build `@sbombs/daily` (npm tarball)
  5. Publish both to registries (using OIDC trusted publishing, no long-lived tokens)
  6. Create Git tag `daily@YYYY.M.D` pointing to HEAD
  7. Push tag to origin
  8. Create GitHub Release (for visibility)

### `yearly.yml`

- **Trigger:** Manual dispatch only
- **Safety checks:**
  1. Verify `yearly@*` tags do NOT already exist (prevent re-publishing)
  2. Require explicit confirmation via workflow input (`confirm_yearly: "yes"`)
  3. Verify npm and PyPI versions match (must be identical)
- **Steps:** Build and publish both registries, create tag, create GitHub Release
- **Post-publish:** Anchor should never be published again; workflow blocks re-runs

## Timezone Considerations

- All dates and times use **UTC**
- CI environment variable: `TZ=UTC` (set explicitly to avoid edge cases)
- Nightly scheduled for **06:00 UTC** (exact time TBD with team; adjust as needed)
- Version dates are computed in UTC: `2026.9.29` is September 29, 2026 UTC, not local time

## Auditing & Forensics

### Example: "What code was published as `daily@2026.9.15`?"

```bash
# Show the commit
git show daily@2026.9.15

# View all files in that commit
git show daily@2026.9.15 --name-only

# See the exact source code of the published package
git show daily@2026.9.15:canaries/npm/daily/index.js
```

### Example: "List all published versions"

```bash
git tag -l "daily@*" | sort -V
git tag -l "yearly@*"
```

### Example: "Verify package integrity"

After publishing, verify the published version matches the source:

```bash
# Download from PyPI
pip download sbombs-daily==2026.9.15 --no-deps

# Extract and compare to source
tar -xzf sbombs-daily-2026.9.15.tar.gz
diff sbombs-daily-2026.9.15/src/sbombs_daily/__init__.py \
      canaries/pypi/sbombs-daily/src/sbombs_daily/__init__.py
```

## Configuration & Secrets

### Required Secrets (GitHub)

- `NPM_TOKEN`: npm authentication token for publishing (or use OIDC)
- `GITHUB_TOKEN`: Pre-provided by GitHub Actions; used for creating tags and releases

### Environment Variables

- `SBOMBS_PENDING_WAIT_HOURS`: Hours to wait after publishing before marking as "no longer pending" in test scenarios (default: 4)

## Troubleshooting

### "Version mismatch: npm vs PyPI"

The `yearly.yml` workflow explicitly checks that npm and PyPI versions match. If they don't:
1. Edit both `canaries/npm/yearly/package.json` and `canaries/pypi/sbombs-yearly/pyproject.toml` to have the same version
2. Commit to a feature branch and create a PR (requires maintainer approval)
3. Merge and re-run yearly workflow

### "Tag already exists for this version"

If you attempt to publish the same version twice, the `git tag` command will fail (cannot create duplicate tag). This is **intentional**: each version should publish once. To fix:
1. Daily: Just wait until the next day; a new version will be computed
2. Yearly: Never attempt to republish (workflow explicitly checks for this)

### "I accidentally edited sbombs-yearly"

1. Do not commit and push the change
2. Create a PR instead (GitHub branch protection requires this anyway)
3. The PR will fail code owner checks; ask a maintainer to reject it
4. Delete the branch and revert your local edits
5. The yearly package remains unmodified in production

## References

- [agents.md](./agents.md) — SBOMBS project guidelines and rules
- [scenarios/immaturity.yaml](./scenarios/immaturity.yaml) — Test scenarios (note: version age is resolved at runtime from registry publish date)
- [.github/workflows/](./\.github/workflows/) — CI/CD workflow files
- [.github/CODEOWNERS](./.github/CODEOWNERS) — Code owner assignments for branch protection
