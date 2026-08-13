---
name: pr-readiness
description: "Prepare a pull request for review. Use when checking changed files, validating tests, writing PR summaries, or identifying review risks before opening a PR."
argument-hint: "Describe the branch or change scope"
---
# PR Readiness

Use this skill before opening or updating a pull request.

## Procedure

1. Inspect changed files and separate intentional changes from generated or unrelated changes.
2. Identify the user-facing behavior, API contract, migration effect, or operational impact.
3. Run the narrowest relevant validation command available in the repository.
4. Summarize what changed, why it changed, and how it was validated.
5. Call out residual risks, missing tests, and follow-up work.

## Output

Return:

- Change summary
- Validation performed
- Risks and mitigations
- Suggested PR title
- Suggested PR description
