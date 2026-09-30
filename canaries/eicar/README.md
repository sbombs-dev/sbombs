# eicar (Phase 2 - template only, not approved)

This directory is a **placeholder** for Phase 2 (malicious-package
policy testing), which is **restricted and not yet approved** by
maintainers. See the "Phase 2: malicious-package testing (restricted)"
section of [`agents.md`](../../agents.md) at the repository root.

## Important

- This directory does **not** contain the literal EICAR test string or
  any other antivirus signature, in any form (encoded or otherwise).
- No file in this repository may ever contain that string literally.
  If Phase 2 is approved, the EICAR file must be generated in CI from
  an encoded form and placed only in a data file that is never
  imported or run.
- Do not add real EICAR content, data files, or publishing logic here
  without explicit maintainer approval.
