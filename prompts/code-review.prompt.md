---
description: "Review a code change for defects, regressions, missing tests, and maintainability risks."
argument-hint: "Scope to review, such as staged changes, a branch diff, or selected files"
agent: "agent"
---
Review the requested change with a bug-focused engineering lens.

Prioritize findings over summary. For each finding include:

- Severity
- File and line reference when available
- What can go wrong
- A concrete fix or mitigation

Also include:

- Missing or weak test coverage
- Open questions or assumptions
- A short change summary only after findings

Do not spend review space on praise or cosmetic preferences unless they hide real risk.
