# SBOMBS

**S**BOM **B**ehavior **O**bservation, **M**anifest & **B**locking **S**uite.

SBOMBS provides a collection of canary packages published to PyPI and npm on a set schedule. 
These small, inert test-fixture packages enable anyone to test their supply chain policies 
with known, predictable package metadata (release dates, versions, etc.).

Full project context, rules, and repository layout are documented in
[`agents.md`](./agents.md). Read it before making changes.

## Status

- ✅ Version control strategy implemented (see [`VERSION_CONTROL.md`](./VERSION_CONTROL.md))
- ✅ Modular package structure set up (yearly + daily)
- ✅ CI workflows scaffolded (daily, yearly)
- ✅ Future-ready for additional dimensions (eicar, license types, etc.)

## Layout

- `canaries/` - inert test-fixture packages (PyPI and npm)
  - `pypi/` - Python packages (sbombs-daily, sbombs-yearly)
  - `npm/` - npm packages (@sbombs/daily, @sbombs/yearly)
- `.github/workflows/` - CI/CD for publishing packages (daily.yml, yearly.yml)

## Key Documentation

- **[`agents.md`](./agents.md)** — Project overview, rules, and repository guidelines. **Start here.**
- **[`VERSION_CONTROL.md`](./VERSION_CONTROL.md)** — How canary versions are managed and tracked in Git.
- **[`CONTRIBUTING.md`](./CONTRIBUTING.md)** — Development guidelines, code review checklist, and testing procedures.

## Packages

SBOMBS publishes modular test-fixture packages to each registry. Current dimensions:

- **`sbombs-daily`** (PyPI) / `@sbombs/daily` (npm)
  - Published daily at 06:00 UTC with version `YYYY.M.D` (e.g., `2026.9.29`)
  - Provides a version of every age for testing immaturity/release-date policies
  - Use to validate any age-based threshold (2 days, 14 days, 30 days, custom)
  
- **`sbombs-yearly`** (PyPI) / `@sbombs/yearly` (npm)
  - Published once per year with semantic version `YYYY.M.0` (e.g., `2026.1.0`)
  - Serves as an immutable control/baseline for validating test setup
  - Always old enough to pass age-based policies

- **`sbombs-wdeps`** (PyPI) / `@sbombs/wdeps` (npm)
  - Published manually with semantic versioning (e.g., `1.0.0`)
  - Contains runtime dependency on `sbombs-daily>=2026.10.8`
  - Use to test transitive dependency resolution, version constraints, and dependency age policies

Most packages are inert (no install scripts, no network calls, no dependencies). **Exception:** `sbombs-wdeps` intentionally has dependencies for testing dependency-related policies.

**Future dimensions** (planned): `sbombs-eicar` (Phase 2), `sbombs-mit`, `sbombs-agpl`, etc.

## Using the Packages

Use these packages to test your own supply chain policies. Example scenarios:

- **Test release-date (immaturity) rules**: Request `sbombs-daily` versions of different ages (e.g., `2026.9.15`, `2026.9.10`)
- **Test pending behavior**: Request today's `sbombs-daily` version (0 hours old)
- **Validate your test setup**: Request `sbombs-yearly` — it should always pass age-based policies; if blocked, your setup needs adjustment
- **Test dependency policies**: Request `sbombs-wdeps` to validate transitive dependency resolution, version constraints, and whether policies check dependency ages

## Development

Testing canary packages locally:

```sh
# For Node.js package testing
cd canaries/npm/daily
npm install

# For Python package testing
cd canaries/pypi/sbombs-daily
python -m build
```

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for more details.
