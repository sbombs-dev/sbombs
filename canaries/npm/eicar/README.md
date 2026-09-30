# @sbombs/eicar (Phase 2 — Restricted, Not Yet Approved)

**Status:** Placeholder only. Phase 2 development not yet approved.

This is a reserved namespace for future malicious-package policy testing. **Do not publish or implement without explicit maintainer approval.**

## Overview

When approved, `@sbombs/eicar` will provide test fixtures for supply chain policies that detect or block known malicious packages. 

## Important Rules

- **Never commit the EICAR test string literally.** It would flag antivirus software and contaminate contributor clones.
- **Never publish to npm without explicit approval.** npm's policies may differ from PyPI.
- **Coordinate with PyPI/npm teams** before implementation to understand their content policy stance.
- **Use encoded/generated approach:** The test signature is generated in CI from an encoded form, never stored literally in the repository.

See [`agents.md`](../../agents.md#phase-2-malicious-package-testing-restricted) for Phase 2 guidelines.
