# sbombs-wdeps

Test fixture for supply-chain policy testing with runtime dependencies. Do not depend on this package.

Published manually for specific test scenarios to validate dependency-related policies
(transitive dependencies, version constraints, dependency age policies, etc.).

See [`agents.md`](../../../agents.md) at the repository root for full context and rules.

## Purpose

This package contains a runtime dependency on `sbombs-daily` with a version constraint
(`>=2026.10.8`). Use it to test:

- Transitive dependency resolution
- Version constraint policies
- Dependency age policies (testing if policies check transitive dependencies)
- Dependency graph analysis

## Key Characteristics

- **Has runtime dependencies** (unlike other SBOMBS packages which are dependency-free)
- **Published manually** for specific test scenarios
- **Minimal code** - contains only version information
- **No install scripts** - no `setup.py` hooks, no network calls, no file writes

## Using This Package

```bash
# Install to test transitive dependency policies
pip install sbombs-wdeps

# This will also install sbombs-daily>=2026.10.8 as a dependency
```

## Version Information

Check the current version:
```python
import sbombs_wdeps
print(sbombs_wdeps.__version__)
```
