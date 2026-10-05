# sbombs-yearly

Test fixture for supply-chain policy testing. Do not depend on this package.

This is the **yearly control** package: it is published once per year and never
republished. It must always pass immaturity/release-date policies. If
it is ever blocked by such a policy, the test setup is wrong, not the
policy. See [`agents.md`](../../../agents.md) at the repository root
for full context and rules.

**Never republish or modify this package within a year.** Its immutable annual release is
the whole point.

This package contains no install scripts, no network calls, no file
writes, and no runtime dependencies.
