# Version Control Strategy for Canary Packages

This document explains how version numbers are managed for the SBOMBS canary packages published to PyPI and npm, and how Git is used to audit and track deployments.

## Overview

**Key principle:** Package versions are **not committed to source code**. Instead, they are **computed at CI runtime** and tracked via **Git tags** that point to the exact source code that was built and published.

This strategy:
- ✅ Prevents version-number merge conflicts in source
- ✅ Allows deterministic, automated versioning (e.g., daily dates for nightly packages)
- ✅ Creates an immutable audit trail in Git history
- ✅ Enables forensic debugging: "What code was released as version X.Y.Z?"

## Versioning Scheme

### Canary Nightly (`sbombs-canary-nightly` / `@sbombs/canary-nightly`)

- **Version format:** `YYYY.M.D` (calendar versioning, UTC date, no leading zeros)
  - Example: `2026.9.29` (September 29, 2026)
- **Computation:** CI computes version at publish time: `date -u +'%Y.%-m.%-d'` (UTC)
- **Release frequency:** Daily at 06:00 UTC via scheduled workflow
- **Source config:** `package.json` and `pyproject.toml` always contain `"version": "0.0.0"` (static placeholder)
- **Rationale:** Nightly canaries must have a version of every age. Each UTC calendar day generates a new version.

### Canary Anchor (`sbombs-canary-anchor` / `@sbombs/canary-anchor`)

- **Version format:** Fixed version, stored in source (e.g., `1.0.0`)
  - Current version: Check `canaries/npm/canary-anchor/package.json` and `canaries/pypi/sbombs-canary-anchor/pyproject.toml`
- **Release frequency:** **One-time only**, never republished
- **Source config:** `package.json` and `pyproject.toml` contain the fixed version (not `0.0.0`)
- **Rationale:** Anchor is a control package. Its single, immutable release serves as a baseline that must always pass immaturity policies.

## Git Tagging Strategy

Every successful publish to PyPI or npm creates a **Git tag** pointing to the exact commit that was built.

### Tag Naming Convention

- **Nightly:** `canary-nightly@YYYY.M.D`
  - Example: `canary-nightly@2026.9.29`
  - New tag created every day

- **Anchor:** `canary-anchor@<version>`
  - Example: `canary-anchor@1.0.0`
  - Created once; should never be created again

### How Tags Are Created

1. CI workflow builds the package from source
2. Package is published to PyPI/npm
3. After successful publish, CI workflow runs:
   ```bash
   git tag -a "canary-nightly@$(date -u +'%Y.%-m.%-d')" \
     -m "Published nightly v$(date -u +'%Y.%-m.%-d')" \
     HEAD
   git push origin <tag>
   ```
4. A GitHub Release is created (optional, for visibility in the web UI)

### Why Tags Matter

Tags are the **primary audit trail**:

- `git show canary-nightly@2026.9.29` → See the exact source code published on that date
- `git tag -l` → List all published versions (view full release history)
- `git log --oneline --decorate` → See release points in the commit history
- Cannot be accidentally deleted (require force push, which is blocked on `main`)

## Branch Protection & Immutability

### Anchor Package Protection

Files under `canaries/npm/canary-anchor/` and `canaries/pypi/sbombs-canary-anchor/` are protected by GitHub branch protection rules:

1. **All direct pushes to `main` are blocked** for these paths
2. **Pull requests are required** for any changes
3. **Code owner approval is required** (assigned to `@sbombs/maintainers` in `.github/CODEOWNERS`)
4. **Stale reviews are dismissed** to prevent old approvals from being reused

**Why?** The anchor control package must never be modified after publication. Any change would corrupt the test baseline.

### Nightly Package Protection

Files under `canaries/npm/canary-nightly/` and `canaries/pypi/sbombs-canary-nightly/` require maintainer review to ensure:
- No install scripts or runtime dependencies are introduced
- Package remains inert and suitable for repeated publication
- Version string remains `0.0.0` in source (CI will compute real version)

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

### `canary-nightly.yml`

- **Trigger:** Schedule (06:00 UTC daily) or manual dispatch
- **Steps:**
  1. Check out code
  2. Compute version as `date -u +'%Y.%-m.%-d'`
  3. Build `sbombs-canary-nightly` (PyPI wheel + sdist)
  4. Build `@sbombs/canary-nightly` (npm tarball)
  5. Publish both to registries (using OIDC trusted publishing, no long-lived tokens)
  6. Create Git tag `canary-nightly@YYYY.M.D` pointing to HEAD
  7. Push tag to origin
  8. Create GitHub Release (for visibility)

### `canary-anchor.yml`

- **Trigger:** Manual dispatch only
- **Safety checks:**
  1. Verify `canary-anchor@*` tags do NOT already exist (prevent re-publishing)
  2. Require explicit confirmation via workflow input (`confirm_anchor: "yes"`)
  3. Verify npm and PyPI versions match (must be identical)
- **Steps:** Build and publish both registries, create tag, create GitHub Release
- **Post-publish:** Anchor should never be published again; workflow blocks re-runs

## Timezone Considerations

- All dates and times use **UTC**
- CI environment variable: `TZ=UTC` (set explicitly to avoid edge cases)
- Nightly scheduled for **06:00 UTC** (exact time TBD with team; adjust as needed)
- Version dates are computed in UTC: `2026.9.29` is September 29, 2026 UTC, not local time

## Auditing & Forensics

### Example: "What code was published as `canary-nightly@2026.9.15`?"

```bash
# Show the commit
git show canary-nightly@2026.9.15

# View all files in that commit
git show canary-nightly@2026.9.15 --name-only

# See the exact source code of the published package
git show canary-nightly@2026.9.15:canaries/npm/canary-nightly/index.js
```

### Example: "List all published versions"

```bash
git tag -l "canary-nightly@*" | sort -V
git tag -l "canary-anchor@*"
```

### Example: "Verify package integrity"

After publishing, verify the published version matches the source:

```bash
# Download from PyPI
pip download sbombs-canary-nightly==2026.9.15 --no-deps

# Extract and compare to source
tar -xzf sbombs-canary-nightly-2026.9.15.tar.gz
diff sbombs-canary-nightly-2026.9.15/src/sbombs_canary_nightly/__init__.py \
      canaries/pypi/sbombs-canary-nightly/src/sbombs_canary_nightly/__init__.py
```

## Configuration & Secrets

### Required Secrets (GitHub)

- `NPM_TOKEN`: npm authentication token for publishing (or use OIDC)
- `GITHUB_TOKEN`: Pre-provided by GitHub Actions; used for creating tags and releases

### Environment Variables

- `SBOMBS_PENDING_WAIT_HOURS`: Hours to wait after publishing before marking as "no longer pending" in test scenarios (default: 4)

## Troubleshooting

### "Version mismatch: npm vs PyPI"

The `canary-anchor.yml` workflow explicitly checks that npm and PyPI versions match. If they don't:
1. Edit both `canaries/npm/canary-anchor/package.json` and `canaries/pypi/sbombs-canary-anchor/pyproject.toml` to have the same version
2. Commit to a feature branch and create a PR (requires maintainer approval)
3. Merge and re-run anchor workflow

### "Tag already exists for this version"

If you attempt to publish the same version twice, the `git tag` command will fail (cannot create duplicate tag). This is **intentional**: each version should publish once. To fix:
1. Nightly: Just wait until the next day; a new version will be computed
2. Anchor: Never attempt to republish (workflow explicitly checks for this)

### "I accidentally edited canary-anchor"

1. Do not commit and push the change
2. Create a PR instead (GitHub branch protection requires this anyway)
3. The PR will fail code owner checks; ask a maintainer to reject it
4. Delete the branch and revert your local edits
5. The anchor remains unmodified in production

## References

- [agents.md](./agents.md) — SBOMBS project guidelines and rules
- [scenarios/immaturity.yaml](./scenarios/immaturity.yaml) — Test scenarios (note: version age is resolved at runtime from registry publish date)
- [.github/workflows/](./\.github/workflows/) — CI/CD workflow files
- [.github/CODEOWNERS](./.github/CODEOWNERS) — Code owner assignments for branch protection
