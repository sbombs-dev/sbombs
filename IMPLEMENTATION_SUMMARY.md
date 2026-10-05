# Package Deployment & Version Control Implementation Summary

**Date:** September 29, 2026  
**Status:** ✅ Complete (Modular Package Naming & Versioning)

This document summarizes the modular package structure and version control strategy for SBOMBS packages.

## What Was Implemented

### 1. Modular Package Structure

**Daily Package** (`sbombs-daily` / `@sbombs/daily`)
- Published daily at 06:00 UTC
- Version: `YYYY.M.D` (e.g., `2026.9.29`)
- Purpose: Provides versions of every age for testing immaturity policies

**Yearly Package** (`sbombs-yearly` / `@sbombs/yearly`)
- Published once per year (manual dispatch)
- Version: `YYYY.M.0` (e.g., `2026.1.0`)
- Purpose: Immutable control baseline for validating test setup

### 2. CI/CD Workflows (`.github/workflows/`)

#### `daily.yml` ✅
- **Trigger:** Daily schedule (06:00 UTC) + manual dispatch
- **Functionality:**
  - Computes version as UTC date: `date -u +'%Y.%-m.%-d'` (e.g., `2026.9.29`)
  - Builds and publishes `sbombs-daily` to PyPI
  - Builds and publishes `@sbombs/daily` to npm
  - Creates Git tag: `daily@YYYY.M.D`
  - Creates GitHub Release for visibility
- **Security:** Uses OIDC trusted publishing (no long-lived tokens)

#### `yearly.yml` ✅
- **Trigger:** Manual dispatch only (with safety checks)
- **Functionality:**
  - Verifies yearly version hasn't been published before
  - Requires explicit `confirm_yearly="yes"` confirmation
  - Validates npm and PyPI versions match
  - Builds and publishes both packages
  - Creates immutable Git tag: `yearly@YYYY.M.0`
  - Creates GitHub Release (annual record)
- **Safety:** Workflow exits if yearly version tag already exists (prevents re-publishing)

### 3. Branch Protection (`CODEOWNERS`)

**File:** `.github/CODEOWNERS`  
**Protection Rules:**
- Yearly packages (`canaries/npm/yearly/`, `canaries/pypi/sbombs-yearly/`) → Requires `@sbombs/maintainers` approval
- Daily packages (recommended for maintainer review)
- CI/CD workflows (`.github/workflows/`) → Requires maintainer approval

**How to enforce in GitHub:**
1. Go to repository Settings → Branches
2. Create/edit rule for branch `main`
3. Enable "Require status checks to pass before merging"
4. Enable "Require code reviews before merging"
5. Set "Required approving reviews" to 1
6. Enable "Dismiss stale pull request approvals when new commits are pushed"
7. Save

### 4. Documentation

#### `VERSION_CONTROL.md` ✅
**Comprehensive guide covering:**
- Versioning schemes: date-based for daily, semantic for yearly
- Git tagging strategy and naming conventions
- Branch protection and immutability enforcement
- Daily vs. yearly CI workflow details
- Timezone considerations (UTC)
- Auditing and forensics examples
- Troubleshooting guide

#### `agents.md` ✅
**Updated with:**
- New modular package naming convention
- Repository layout for daily + yearly packages
- Placeholder structure for Phase 2 (sbombs-eicar)
- Future-ready guidance for license-based packages
- Naming patterns for new dimensions

#### `CONTRIBUTING.md` ✅
**Development guidelines including:**
- Package inertness requirements (no install scripts, runtime deps, etc.)
- Yearly package immutability warning
- Version control specifics for daily vs. yearly packages
- Code review checklist
- Local testing procedures
- New dimension proposal guidelines

#### `README.md` (updated) ✅
- Updated package names and descriptions
- Added future-ready note about modular dimensions
- Updated development examples
- Updated package usage scenarios

### 4. Local Development Support

#### `.git-hooks/pre-commit` ✅
- **Purpose:** Local warning hook (not a blocker)
- **Behavior:** Warns developers if they attempt to commit changes to anchor packages
- **Installation:** Run `./setup-dev-env.sh` or manually: `git config core.hooksPath .git-hooks`

#### `setup-dev-env.sh` ✅
- **Purpose:** One-command environment setup
- **Functionality:**
  - Configures local Git hooks
  - Installs Python dev dependencies (optional)
  - Installs Node.js dependencies for canaries (optional)
  - Prints helpful next steps

#### `versions.json` ✅
- **Purpose:** Human-readable audit log (informational only)
- **Content:** Tracks latest published versions, registries, and Git tags
- **Maintenance:** Updated by CI after successful publishes
- **Note:** Not used by CI to determine versions; purely informational

## Key Design Decisions

| Decision | Rationale |
|---|---|
| **Versions not in source** | Prevents merge conflicts; enables automated date-based versioning |
| **Git tags as audit trail** | Immutable record of what code was published when; enables forensics |
| **OIDC trusted publishing** | No long-lived registry tokens stored in secrets; more secure |
| **Branch protection rules** | Prevents accidental modifications to anchor package post-publication |
| **UTC everywhere** | Eliminates timezone confusion; consistent versioning across regions |
| **Optional pre-commit hook** | Local friction to reduce mistakes, but GitHub rules are the real safeguard |

## Verification Checklist

Before going to production, complete these checks:

- [ ] **Confirm `package.json` and `pyproject.toml` versions:** All daily configs have `version = "0.0.0"`; yearly configs have semantic version (check: `grep -r '"version"' canaries/`)
- [ ] **Test daily workflow locally:** Use `act` to dry-run `.github/workflows/daily.yml`
  ```bash
  brew install act  # or install via your package manager
  act schedule --job publish-daily  # Simulates scheduled run
  ```
- [ ] **Verify OIDC setup:** Confirm PyPI and npm have OIDC trusted publishing configured for this repo (see npm and PyPI docs)
- [ ] **Test branch protection:** Create a test branch, edit `canaries/npm/yearly/package.json`, open PR:
  - Verify GitHub prevents merge without approval from `@sbombs/maintainers`
  - Verify approval can be dismissed and re-requested
- [ ] **Set up CODEOWNERS:** Ensure `@sbombs/maintainers` GitHub team exists and includes appropriate members
- [ ] **Test yearly workflow:** Create a draft PR with yearly changes; ensure workflow won't block legitimate changes during testing
- [ ] **Document secrets:** Add `NPM_TOKEN` (if not using OIDC) to GitHub repo secrets
- [ ] **Create GitHub release environment:** Enable "Environments" in Settings for staged deployments (optional)
- [ ] **Test Git tag cleanup:** Verify tag naming and that old tags don't interfere with new publishes

## File Manifest

```
.github/
  CODEOWNERS                    ← Code owner assignments for branch protection
  workflows/
    daily.yml                   ← Daily publish workflow + git tag
    yearly.yml                  ← Manual annual publish + git tag + confirmation
.git-hooks/
  pre-commit                    ← Local warning hook (optional)
VERSION_CONTROL.md              ← Version control guide (daily + yearly)
agents.md                       ← Updated with modular structure + Phase 2 placeholders
CONTRIBUTING.md                 ← Development guidelines (updated)
README.md                       ← Updated with new package names and structure
setup-dev-env.sh                ← Developer environment setup script
versions.json                   ← Audit log (informational, CI-maintained)
IMPLEMENTATION_SUMMARY.md       ← This file
canaries/
  npm/
    daily/                      ← sbombs-daily npm package
    yearly/                     ← sbombs-yearly npm package
    eicar/                      ← Phase 2 placeholder (not for production)
  pypi/
    sbombs-daily/              ← sbombs-daily PyPI package
    sbombs-yearly/             ← sbombs-yearly PyPI package
    sbombs-eicar/              ← Phase 2 placeholder (not for production)
```

## Next Steps

### For maintainers:

1. **Review and merge this PR**
2. **Configure OIDC trusted publishing:**
   - PyPI: https://docs.pypi.org/trusted-publishers/
   - npm: https://docs.npmjs.com/cli/v9/using-npm/security-best-practices#use-automation-tokens-for-automation
3. **Set up branch protection rules** in GitHub (see "Verification Checklist" above)
4. **Create `@sbombs/maintainers` GitHub team** (or adjust CODEOWNERS to match existing team)
5. **Dry-run daily workflow** against test registry before first production run
6. **Dry-run yearly workflow** with confirmation dialogs enabled
7. **Update npm scope** (@sbombs) to use OIDC if not already configured

### For contributors:

1. **Run `./setup-dev-env.sh`** to enable local Git hooks
2. **Read `VERSION_CONTROL.md`** to understand daily vs. yearly versioning
3. **Read `CONTRIBUTING.md`** for development guidelines
4. **See `agents.md`** for project rules and modular structure
5. **Learn naming convention** for adding new package dimensions

## Examples

### Example: Query published versions

```bash
# List all published daily versions
git tag -l "daily@*" | sort -V

# List all published yearly versions
git tag -l "yearly@*" | sort -V

# See what code was in a specific daily release
git show daily@2026.9.25 --stat

# See what code was in a specific yearly release
git show yearly@2026.1.0 --stat
```

### Example: Audit trail

```bash
# "What code was published as daily@2026.9.29?"
git show daily@2026.9.29

# "When was this commit published?"
git tag --contains abc1234def56

# "Show all releases in order"
git log --oneline --decorate --all --graph
```

### Example: Recover from mistake (if tag pushed accidentally)

```bash
# Delete local tag
git tag -d daily@2026.9.29

# Delete remote tag (requires push rights; use with care)
git push origin :refs/tags/daily@2026.9.29
```

## Questions & Troubleshooting

**Q: Can I manually publish a canary package?**  
A: No. Only CI workflows can publish (to production). For local testing, use a test registry (PyPI Test, Verdaccio for npm).

**Q: What if the nightly version already exists?**  
A: This shouldn't happen (versions are based on UTC date, one per day). If it does, you either:
  1. Re-ran the workflow on the same UTC day (just wait for tomorrow's run)
  2. Manually published (which violates the rules; see agents.md)

**Q: Can I edit sbombs-yearly after publishing?**  
A: Not in production. Branch protection rules prevent edits. If you must test changes:
  1. Create a feature branch
  2. Make changes
  3. Do NOT merge to `main` (or test in a separate `test-yearly` branch)

**Q: How do I verify a published package matches the source?**  
A: See "Auditing & Forensics" section in `VERSION_CONTROL.md` for detailed steps.

## References

- [agents.md](./agents.md) — Project rules and philosophy
- [VERSION_CONTROL.md](./VERSION_CONTROL.md) — Detailed versioning guide
- [CONTRIBUTING.md](./CONTRIBUTING.md) — Development guidelines
- [PyPI Trusted Publishers](https://docs.pypi.org/trusted-publishers/)
- [npm Automation Tokens](https://docs.npmjs.com/cli/v9/using-npm/security-best-practices#use-automation-tokens-for-automation)
- [GitHub Actions](https://docs.github.com/actions)

---

**Implemented by:** GitHub Copilot  
**Status:** Ready for review and testing
