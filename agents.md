# AGENTS.md

> Context and rules for AI coding agents (Copilot, Claude, Cursor, Codex, etc.) working in this repository. Read this fully before making changes.

## Project: SBOMBS

**SBOMBS** stands for **S**BOM **B**ehavior **O**bservation, **M**anifest & **B**locking **S**uite.

SBOMBS provides a collection of **modular test-fixture packages** published to PyPI and npm on a set schedule. These small, inert packages have predictable metadata (release dates, versions, etc.) so users can test their own supply chain policies against real package manager registries.

Packages are published to the public registries to enable real-world testing of supply chain policies through production package manager paths.

## Why this exists

Supply chain policies need test fixtures to verify they work correctly. SBOMBS provides those fixtures:

- **Real test data**: published to the real registries (PyPI, npm) so you can test with production package manager paths
- **Modular dimensions**: separate packages for each policy dimension (daily versions, yearly control, license types, malicious packages, etc.)
- **Predictable versions**: `sbombs-daily` publishes a new version **every day**, so versions of every age are always available
- **Immutable control**: `sbombs-yearly` is an old, immutable version that always passes age-based policies (validates your test setup)
- **Reusable**: test fixtures work with any policy engine or policy type (not tied to a specific tool)

## Current focus: release date (immaturity) rules

Many supply chain policies can block package versions **younger than X days** ("immature" versions). Built-in levels are commonly 2, 14, and 30 days, and custom conditions allow any number. Release dates are typically read from package registries or catalogs, not from the package file itself. That is why packages must be released publicly.

To test any threshold, `sbombs-daily` publishes a new version **every day**, so there is always a version of every age.

Key facts that affect test design:

- New public versions may take time to propagate through catalog systems. During this window, policies may report them as **"Pending"** or similar. Each policy has a separate setting for whether pending packages are blocked or allowed.
- A version's age grows every day, so expected results change over time. Scenarios define ages **relative to the current UTC date**, never as fixed version numbers.
- The runner should work against various policy engines (Curation, Xray, or others), so adapter implementations handle engine-specific details.

## Policy dimensions (roadmap)

| Phase | Dimension | Packages | Approach |
|---|---|---|---|
| 1 (now) | **Release date / immaturity** | `sbombs-daily`, `sbombs-yearly` | Daily snapshots (YYYY.M.D) + annual control (YYYY.M.0) |
| 1 | **Pending catalog window** | `sbombs-daily` | Request today's version within 0–4 hours of publishing |
| 1 (now) | **Dependency policies** | `sbombs-wdeps` | Package with runtime dependencies for testing transitive dependency resolution, version constraints, and dependency age policies |
| 2 | **Malicious package policy** | `sbombs-eicar` | See "Phase 2" below. Restricted and not yet approved |
| Later | **License** | `sbombs-mit`, `sbombs-agpl`, etc. | License-specific test fixtures |
| Later | **Single-version / operational risk** | Various | Other policy dimensions |

## Repository layout

```
sbombs.packages/
├── canaries/
│   ├── pypi/
│   │   ├── sbombs-daily/       # Published daily (YYYY.M.D)
│   │   ├── sbombs-yearly/      # Published yearly (YYYY.M.0)
│   │   ├── sbombs-wdeps/       # Published manually (semantic versioning)
│   │   └── sbombs-eicar/       # Phase 2: placeholder. NO literal test string
│   ├── npm/
│   │   ├── daily/              # Published as @sbombs/daily (YYYY.M.D)
│   │   ├── yearly/             # Published as @sbombs/yearly (YYYY.M.0)
│   │   ├── wdeps/              # Published as @sbombs/wdeps (semantic versioning)
│   │   └── eicar/              # Phase 2: placeholder. NO literal test string
└── .github/workflows/
    ├── daily.yml               # Cron 06:00 UTC, publishes PyPI + npm daily
    └── yearly.yml              # Manual trigger, publishes PyPI + npm yearly
```

## Packages

| Package | Release pattern | Versioning | Purpose |
|---|---|---|---|
| `sbombs-daily` | Daily at 06:00 UTC | `YYYY.M.D` (e.g., `2026.9.29`) | Supplies versions of every age for testing immaturity thresholds |
| `sbombs-yearly` | Once per year (manual) | `YYYY.M.0` (e.g., `2026.1.0`) | **Control**: immutable baseline. If blocked, test setup is wrong, not the policy |
| `sbombs-wdeps` | Manual / on-demand | Semantic (e.g., `1.0.0`) | **Dependency testing**: has runtime dependency on `sbombs-daily>=2026.10.8` for testing transitive dependencies, version constraints, and dependency age policies |

**Versioning strategy:**
- **Daily (`YYYY.M.D`)**: One unique version per day in UTC. Each day increments the minor version; never reused.
- **Yearly (`YYYY.M.0`)**: Semantic versioning with year in major position. Major increments annually; minor = release count within year (1, 2, 3…); patch reserved for hotfixes. Example: `2026.1.0` (first 2026 release), `2027.1.0` (first 2027 release).
- **Wdeps (semantic)**: Standard semantic versioning (`MAJOR.MINOR.PATCH`). Version bumped when dependency constraints change or for testing different scenarios.

## ⚠️ Critical rules for agents

1. **Packages must stay inert.** No install scripts (`preinstall`/`postinstall`, custom `setup.py` commands), no network calls, no file writes, no code beyond a version string. **Exception:** `sbombs-wdeps` intentionally has runtime dependencies for testing dependency policies. Each README must say: *"Test fixture for supply-chain policy testing. Do not depend on this package."*
2. **Only packages in `canaries/` may be published publicly, and only through the release workflows.** Never publish from a local machine, and never add a manual `npm publish` or `twine upload` step outside `.github/workflows/`.
3. **Never unpublish, yank, or deprecate package versions.** Old versions are the test data. Deprecation can also trigger other policy conditions and corrupt age results.
4. **Do not add new daily packages or increase release frequency without maintainer approval.** PyPI prohibits excessive automated bulk activity. One release per package per day is the limit.
5. **Never republish or modify `sbombs-yearly`.** Its annual, immutable release is the baseline. Version must match between PyPI and npm.
6. **Never commit the EICAR test string (or any AV signature) literally**, in any file, commit message, issue, or test. It would get the repo and contributors' clones flagged by antivirus software.
7. **Never publish EICAR or any other dual-use/security-research content to PyPI.** PyPI's policy forbids it, and enforcement is permanent. npm may have different policies for Phase 2.
8. **Use trusted publishing (OIDC) only.** No long-lived registry tokens in secrets or code.
9. **Do not "fix" packages or fixtures** that look outdated, oddly versioned, or unlicensed. They are built that way on purpose.
10. **For modular dimensions**: When adding a new package dimension (e.g., `sbombs-mit`, `sbombs-eicar`), follow the same naming pattern: `sbombs-[dimension]` on PyPI, `@sbombs/[dimension]` on npm. Maintain inertness and immutability rules.

## Phase 2: malicious-package testing (restricted)

Not approved yet. If a maintainer explicitly asks for it:

- The EICAR file is **generated in CI from an encoded form** and placed only in a **data file** that is never imported or run.
- Publish it **only to npm**, from the **`@sbombs` org** (following consistent naming: `@sbombs/eicar`), with the `contentPolicy` declaration, a `DISCLOSURE` file, and 2FA/staged publishing.
- Prefer testing the malicious-package *policy* against a known, already-removed malicious package name, or by blocking a label placed on a harmless package in the policy engine's catalog system.

## For maintainers

- **New package dimension** (e.g., license types, malicious packages): add new package(s) under `canaries/pypi/sbombs-[dimension]/` and `canaries/npm/[dimension]/`.
- **Naming convention**: PyPI uses `sbombs-[dimension]` (e.g., `sbombs-mit`, `sbombs-eicar`), npm uses scoped `@sbombs/[dimension]`.
- **Update package metadata**: only modify files under `canaries/` — never modify published versions.
- **Version numbering**: 
  - Daily packages (e.g., `sbombs-daily`): strictly follow `YYYY.M.D` format
  - Yearly packages (e.g., `sbombs-yearly`): follow `YYYY.M.0` semantic versioning
  - Other packages: use immutable semantic versioning (1.0.0, 2.0.0, etc.) or date-based as appropriate
- **Never republish or deprecate**: old versions are test data and must remain available forever.
- **Copilot outputs**: Save AI-generated markdown files (setup checklists, implementation summaries, troubleshooting notes) to `copilot-outputs/` — this directory is git-ignored and for local development only.

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for detailed development guidelines (maintainers only).
