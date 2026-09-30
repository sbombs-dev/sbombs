# SBOMBS

**S**BOM **B**ehavior **O**bservation, **M**anifest & **B**locking **S**uite.

SBOMBS tests software supply chain policies (mainly JFrog Curation, and
later Xray) in Artifactory. It publishes small, inert "canary" packages
to the public registries (PyPI and npm) on a set schedule, then uses a
Python runner to request those canaries through Artifactory remote
repositories and verify that each policy blocks, allows, or leaves
pending each request as expected.

Full project context, rules, and repository layout are documented in
[`agents.md`](./agents.md). Read it before making changes.

## Status

Phase 1 scaffolding in progress:
- ✅ Version control strategy implemented (see [`VERSION_CONTROL.md`](./VERSION_CONTROL.md))
- ✅ CI workflows scaffolded (canary-nightly, canary-anchor)
- ⏳ Runner logic to be implemented
- ⏳ Test execution infrastructure

## Layout

- `src/sbombs/` - the Python runner (core scenario/verdict logic + vendor adapters)
- `canaries/` - inert test-fixture packages published to PyPI and npm
- `scenarios/` - YAML scenario definitions the runner executes
- `tests/` - unit tests for the runner
- `.github/workflows/` - CI/CD for publishing canaries and running tests

## Key Documentation

- **[`agents.md`](./agents.md)** — Project overview, rules, and repository guidelines. **Start here.**
- **[`VERSION_CONTROL.md`](./VERSION_CONTROL.md)** — How canary versions are managed and tracked in Git.
- **[`CONTRIBUTING.md`](./CONTRIBUTING.md)** — Development guidelines, code review checklist, and testing procedures.

## Development

This project uses [uv](https://docs.astral.sh/uv/) for Python packaging.

### Quick Start

```sh
# Set up dev environment (installs hooks, dependencies)
./setup-dev-env.sh

# Run tests
uv sync
uv run pytest

# For Node.js canary package testing
cd canaries/npm/canary-nightly
npm install
```

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for more details.
