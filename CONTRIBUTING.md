# Contributing to SBOMBS

This document is for maintainers of the SBOMBS canary package collection.

This repository is **maintainer-only** — public contributions are not accepted.

## Standards

- Be respectful and professional in all work
- Follow the critical rules in [`agents.md`](./agents.md)
- Maintain package inertness at all times

## Getting Started

This repository is **maintainer-only**. Public contributions, issues, and discussions are not accepted at this time.

The canary packages themselves are public and available on PyPI and npm for external users to test their supply chain policies.

For maintainers:
1. **Clone the repository** locally
2. **Create a feature branch**: `git checkout -b feature/my-feature`
3. **Make your changes** and test them
4. **Commit your changes** with clear messages
5. **Push to the repository**
6. **Merge to `main`** with required approvals

## Development Guidelines

### Canary Package Requirements (Critical)

Canary packages are **test fixtures** for supply chain policy testing. They must remain **completely inert**:

- ✅ **DO:** Include only version info, README, and minimal metadata
- ❌ **DON'T:** Add install scripts (`preinstall`, `postinstall`, `setup.py` hooks)
- ❌ **DON'T:** Add runtime dependencies
- ❌ **DON'T:** Make network calls or write files
- ❌ **DON'T:** Include compiled C extensions or binary code
- ❌ **DON'T:** Deprecate or yank old versions (they are test data)

**Why?** Canary packages are **published to public registries** (PyPI, npm). Any active code runs in users' environments during installation, which defeats the purpose of testing passive policies. Keeping them inert ensures we're testing the *policy behavior*, not package behavior.

### Anchor Package Warning

Files in `canaries/npm/canary-anchor/` and `canaries/pypi/sbombs-canary-anchor/` are **immutable** after publication. 

- **Never** modify these packages for production
- **Never** republish an anchor version
- If you must make changes for testing, create a **separate test branch** and do not merge to `main`
- GitHub branch protection rules require maintainer approval for any edits

### Version Control for Canary Packages

**All package versions are computed at CI runtime, not in source code.**

- Canary package `package.json` and `pyproject.toml` files contain `version = "0.0.0"` (placeholder)
- CI workflows compute real versions:
  - **Nightly:** `date -u +'%Y.%-m.%-d'` (UTC date, e.g., `2026.9.29`)
  - **Anchor:** Fixed version stored in config (e.g., `1.0.0`)
- After successful publish, CI creates a Git tag: `canary-nightly@YYYY.M.D` or `canary-anchor@<version>`
- Git tags serve as the audit trail

**Do not:**
- Manually edit package version fields before publishing (CI will override)
- Try to publish packages manually from your local machine (only CI can publish)
- Unpublish, deprecate, or yank released versions (they are test data)

See [VERSION_CONTROL.md](./VERSION_CONTROL.md) for details.

### Continuous Integration & Workflows

#### Canary Nightly Workflow

- **File:** `.github/workflows/canary-nightly.yml`
- **Trigger:** Scheduled daily at 06:00 UTC
- **Publishes:** `sbombs-canary-nightly` (PyPI) and `@sbombs/canary-nightly` (npm)
- **Version:** Computed as UTC date (e.g., `2026.9.29`)
- **Git tag:** `canary-nightly@<date>`

#### Canary Anchor Workflow

- **File:** `.github/workflows/canary-anchor.yml`
- **Trigger:** Manual dispatch only (with maintainer approval)
- **Publishes:** `sbombs-canary-anchor` (PyPI) and `@sbombs/canary-anchor` (npm)
- **Git tag:** `canary-anchor@<version>`
- **Note:** After first successful publish, **do not run this workflow again**

### Code Review Checklist

When reviewing pull requests, check:

- [ ] **Inertness:** No install scripts, runtime deps, network calls, or file writes
- [ ] **Version unchanged:** Canary configs still have `0.0.0`; anchor version matches across npm and PyPI
- [ ] **Anchor safety:** If editing `canary-anchor/*`, is there a documented reason? (Usually shouldn't happen post-publish)
- [ ] **Documentation:** Changes to canary packages or CI workflows are documented

## Proposing New Canary Packages

For new policy dimensions (e.g., license-based testing, malicious package detection), maintainers should:

1. **Plan** the approach and new canary package(s)
2. **Design** the new canary package(s) under `canaries/pypi/` or `canaries/npm/`
3. **Ensure inertness:** No install scripts, runtime deps, or active behavior
4. **Document** the new canary in `README.md` and `agents.md`
5. **Plan release schedule:** How often will it be published?

## Security Issues

For security vulnerabilities in the canary packages or publishing infrastructure:

- **Email maintainers privately** (see `SECURITY.md` if present)
- Include details about the vulnerability and potential impact
- Do not open public issues for security concerns

## Local Verification

### Testing Canary Package Inertness

For npm packages:
```bash
cd canaries/npm/canary-nightly
npm install  # Should install quickly with no side effects
npm list     # Should show only the package itself, no dependencies
```

For Python packages:
```bash
cd canaries/pypi/sbombs-canary-nightly
pip install .  # Should install instantly with no dependencies
python -c "import sbombs_canary_nightly"  # Should work
```

For PyPI packages:
```bash
cd canaries/pypi/sbombs-canary-nightly
pip install -e .  # Should install quickly with no side effects
python -c "from sbombs_canary_nightly import *; print('Inert - no runtime behavior')"
```

### Manual Publishing (Testing Only)

**Do NOT publish to production registries manually.** For local testing:

```bash
# Test against PyPI's test registry
cd canaries/pypi/sbombs-canary-nightly
pip install build twine
python -m build
twine upload --repository testpypi dist/*

# Test against a local npm registry (e.g., Verdaccio)
# See https://verdaccio.org/ for setup
cd canaries/npm/canary-nightly
npm publish --registry http://localhost:4873
```

## Commit Message Guidelines

- Use present tense: "Add feature" not "Added feature"
- Reference issues: "Fixes #123" or "Closes #456"
- Keep first line under 50 characters
- Provide context in the body (what, why, not just what)

Example:
```
Add pending-window scenario for 4-hour catalog delay

Policy engines should mark packages as "Pending" until their
catalog updates. This scenario tests that behavior.

Fixes #42
```

## License

All contributions are licensed under the same license as this project (MIT).

## More Information

- [README.md](./README.md) — Project overview and canary package usage
- [VERSION_CONTROL.md](./VERSION_CONTROL.md) — Version control strategy and Git tags
- [agents.md](./agents.md) — SBOMBS rules and philosophy

Thank you for helping make supply chain policy testing better! 🚀
