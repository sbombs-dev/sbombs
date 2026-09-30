# SBOMBS

**S**BOM **B**ehavior **O**bservation, **M**anifest & **B**locking **S**uite.

SBOMBS provides a collection of canary packages published to PyPI and npm on a set schedule. 
These small, inert test-fixture packages enable anyone to test their supply chain policies 
with known, predictable package metadata (release dates, versions, etc.).

Full project context, rules, and repository layout are documented in
[`agents.md`](./agents.md). Read it before making changes.

## Status

- ✅ Version control strategy implemented (see [`VERSION_CONTROL.md`](./VERSION_CONTROL.md))
- ✅ Canary package structure set up
- ✅ CI workflows scaffolded (canary-nightly, canary-anchor)

## Layout

- `canaries/` - inert test-fixture packages (PyPI and npm)
  - `pypi/` - Python packages (sbombs-canary-nightly, sbombs-canary-anchor)
  - `npm/` - npm packages (@sbombs/canary-nightly, @sbombs/canary-anchor)
- `.github/workflows/` - CI/CD for publishing canaries

## Key Documentation

- **[`agents.md`](./agents.md)** — Project overview, rules, and repository guidelines. **Start here.**
- **[`VERSION_CONTROL.md`](./VERSION_CONTROL.md)** — How canary versions are managed and tracked in Git.
- **[`CONTRIBUTING.md`](./CONTRIBUTING.md)** — Development guidelines, code review checklist, and testing procedures.

## Canary Packages

SBOMBS publishes two types of canaries to each registry:

- **`canary-nightly`** (PyPI: `sbombs-canary-nightly`, npm: `@sbombs/canary-nightly`)
  - Published daily at 06:00 UTC with version `YYYY.M.D` (e.g., `2026.9.29`)
  - Provides a version of every age for testing immaturity/release-date policies
  
- **`canary-anchor`** (PyPI: `sbombs-canary-anchor`, npm: `@sbombs/canary-anchor`)
  - Published once, never updated — serves as a control
  - Always old enough to pass age-based policies
  - Validates that the test setup is correct

All canaries are inert: no install scripts, no network calls, no dependencies.

## Using the Canaries

Use these packages to test your own supply chain policies. Example scenarios:

- **Test release-date (immaturity) rules**: Request `canary-nightly` versions of different ages
- **Test pending behavior**: Request today's `canary-nightly` version (0 hours old)
- **Validate your test setup**: Request `canary-anchor` — it should always pass age-based policies

## Development

Set up environment:

```sh
./setup-dev-env.sh

# For Node.js canary package testing
cd canaries/npm/canary-nightly
npm install
```

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for more details.
