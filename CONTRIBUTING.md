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

### Yearly Package Warning

Files in `canaries/npm/yearly/` and `canaries/pypi/sbombs-yearly/` are **immutable** after publication. 

- **Never** modify these packages for production
- Never republish a yearly version
- If you must make changes for testing, create a **separate test branch** and do not merge to `main`
- GitHub branch protection rules require maintainer approval for any edits

### Version Control for Packages

**Version management varies by package type:**

**Daily packages** (`sbombs-daily`/`@sbombs/daily`):
- `package.json` and `pyproject.toml` contain `version = "0.0.0"` (placeholder)
- CI computes real version at publish time: `date -u +'%Y.%-m.%-d'` (UTC date, e.g., `2026.9.29`)
- After successful publish, CI creates a Git tag: `daily@YYYY.M.D`

**Yearly packages** (`sbombs-yearly`/`@sbombs/yearly`):
- `package.json` and `pyproject.toml` contain semantic version (e.g., `2026.1.0`)
- Version is **not** computed; it must be manually updated before publishing
- After successful publish, CI creates a Git tag: `yearly@YYYY.M.0`
- Git tags serve as the audit trail for all packages

**Do not:**
- Manually edit package version fields before publishing (CI will override)
- Try to publish packages manually from your local machine (only CI can publish)
- Unpublish, deprecate, or yank released versions (they are test data)

See [VERSION_CONTROL.md](./VERSION_CONTROL.md) for details.

### Continuous Integration & Workflows

#### Daily Workflow

- **File:** `.github/workflows/daily.yml`
- **Trigger:** Scheduled daily at 06:00 UTC
- **Publishes:** `sbombs-daily` (PyPI) and `@sbombs/daily` (npm)
- **Version:** Computed as UTC date (e.g., `2026.9.29`)
- **Git tag:** `daily@<date>`

#### Yearly Workflow

- **File:** `.github/workflows/yearly.yml`
- **Trigger:** Manual dispatch only (with maintainer confirmation)
- **Publishes:** `sbombs-yearly` (PyPI) and `@sbombs/yearly` (npm)
- **Git tag:** `yearly@<version>`
- **Note:** Maintainer must confirm publish and verify version matches between PyPI and npm. After each year's release, do not re-run until next year's version is ready.

### Code Review Checklist

When reviewing pull requests, check:

- [ ] **Inertness:** No install scripts, runtime deps, network calls, or file writes
- [ ] **Version consistency:** Daily configs have `0.0.0`; yearly version matches across npm and PyPI
- [ ] **Yearly safety:** If editing `yearly/*`, is there a documented reason? (Usually shouldn't happen post-publish)
- [ ] **Documentation:** Changes to canary packages or CI workflows are documented

## Proposing New Canary Packages

For new policy dimensions (e.g., license-based testing, malicious package detection), maintainers should:

1. **Plan** the approach and new canary package(s)
2. **Design** the new canary package(s) under `canaries/pypi/` or `canaries/npm/`
3. **Ensure inertness:** No install scripts, runtime deps, or active behavior
4. **Document** the new canary in `README.md` and `agents.md`
- **Plan release schedule:** How often will it be published? (Daily, weekly, once per year, etc.)
- **Follow naming convention:** PyPI uses `sbombs-[dimension]`, npm uses `@sbombs/[dimension]`

## Security Issues

For security vulnerabilities in the canary packages or publishing infrastructure:

- **Email maintainers privately** (see `SECURITY.md` if present)
- Include details about the vulnerability and potential impact
- Do not open public issues for security concerns

## Local Verification

### Testing Package Inertness

For npm packages (daily):
```bash
cd canaries/npm/daily
npm install  # Should install quickly with no side effects
npm list     # Should show only the package itself, no dependencies
```

For Python packages (daily):
```bash
cd canaries/pypi/sbombs-daily
pip install .  # Should install instantly with no dependencies
python -c "import sbombs_daily"  # Should work
python -c "from sbombs_daily import *; print('Inert - no runtime behavior')"
```

For yearly packages:
```bash
cd canaries/npm/yearly
npm install  # Should install quickly with no side effects

cd canaries/pypi/sbombs-yearly
pip install .  # Should install instantly with no dependencies
python -c "import sbombs_yearly"  # Should work
```

### Manual Publishing (Testing Only)

**Do NOT publish to production registries manually.** For local testing:

```bash
# Test against PyPI's test registry (daily package)
cd canaries/pypi/sbombs-daily
pip install build twine
python -m build
twine upload --repository testpypi dist/*

# Test against a local npm registry (e.g., Verdaccio)
# See https://verdaccio.org/ for setup
cd canaries/npm/daily
npm publish --registry http://localhost:4873
```

## Copilot Prompts & Instructions

Reusable GitHub Copilot prompts live in [`.github/prompts/`](./.github/prompts/). In VS Code Copilot Chat, run them by typing `/` followed by the prompt name:

| Prompt | Purpose |
|---|---|
| `/review-canary-pr` | Review a branch or PR against the code review checklist and critical rules |
| `/new-canary-dimension` | Scaffold an inert `sbombs-[dimension]` / `@sbombs/[dimension]` pair and update the docs |
| `/verify-inertness` | Run static checks and isolated install checks on canary packages |
| `/audit-published-version` | Compare a `daily@…` / `yearly@…` tag with the registry artifacts (read-only) |
| `/prepare-yearly-release` | Bump both yearly manifests for a new year on a branch (never republishes) |
| `/troubleshoot-workflow` | Diagnose a failed daily or yearly publish run |
| `/commit-message` | Draft a commit message for staged changes that follows the guidelines below |

Copilot also applies the rules in [`.github/instructions/`](./.github/instructions/) automatically when editing matching files: `canaries.instructions.md` for `canaries/**` and `workflows.instructions.md` for `.github/workflows/**`. Repository-wide agent rules stay in [agents.md](./agents.md).

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
