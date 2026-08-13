---
name: code-review
description: "Review a code change for defects, regressions, security risks, missing tests, and maintainability risks. Use when asked to review staged changes, branch diffs, pull requests, or selected files."
argument-hint: "Scope to review, such as staged changes, a branch diff, a pull request, or selected files"
---
# Code Review

Review the requested change with a bug-focused engineering lens.

Prioritize findings over summary. For each finding include:

- Severity
- File and line reference when available
- What can go wrong
- A concrete fix or mitigation

Also include:

- Any security risk introduced or left unmitigated, such as unsafe input handling, authz/authn gaps, secret exposure, injection risk, insecure defaults, or risky dependency changes
- Missing or weak test coverage
- Open questions or assumptions
- A short change summary only after findings

Do not spend review space on praise or cosmetic preferences unless they hide real risk.