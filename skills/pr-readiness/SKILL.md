---
name: pr-readiness
description: "Prepare a pull request for review. Use when checking changed files, validating tests, writing PR summaries, or identifying review risks before opening a PR."
argument-hint: "Describe the branch or change scope"
---
# PR Readiness

Use this skill before opening or updating a pull request.

## Procedure

1. Resolve the PR base branch by preferring `origin/main`, then `origin/master`, then the local `main` or `master` branch.
2. Inspect the branch diff against that base branch, such as `git diff --stat <base>...HEAD` and `git diff <base>...HEAD`, and separate intentional changes from generated or unrelated changes.
3. Identify the user-facing behavior, API contract, migration effect, security impact, or operational impact.
4. Run the narrowest relevant validation command available in the repository.
5. Summarize what changed, why it changed, and how it was validated.
6. Call out residual risks, missing tests, and follow-up work.

## Output

Return:

- Change summary
- Validation performed
- Risks and mitigations
- Suggested PR title
- Suggested PR description

Format the suggested PR description with this template:

```md
## Summary
- <What changed>
- <Why it changed>

## Changes
- <Important implementation or documentation change>
- <Important implementation or documentation change>

## Validation
- <Command or check run, with result>

## Risks and Follow-up
- <Remaining risk, missing test, or "None identified">
```
