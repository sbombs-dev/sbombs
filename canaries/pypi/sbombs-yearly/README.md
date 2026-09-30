# sbombs-canary-anchor

Test fixture for supply-chain policy testing. Do not depend on this package.

This is the **control** canary: it is published once and never
republished. It must always pass immaturity/release-date policies. If
it is ever blocked by such a policy, the test setup is wrong, not the
policy. See [`agents.md`](../../../agents.md) at the repository root
for full context and rules.

**Never republish or modify this package.** Its single, old release is
the whole point.

This package contains no install scripts, no network calls, no file
writes, and no runtime dependencies.
