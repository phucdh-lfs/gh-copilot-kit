---
description: "Use when writing, modifying, reviewing, or testing production code for this team. Covers engineering standards, validation, and change discipline."
---
# Team Engineering Standards

- Prefer small, focused changes that preserve existing public APIs unless the task requires an API change.
- Read nearby code before introducing new abstractions.
- Follow the repository's existing formatter, test framework, naming conventions, and dependency patterns.
- Validate behavior with the narrowest relevant test or build command after editing code.
- Do not fix unrelated defects in the same change unless they block the requested work.
- Document operationally important decisions in the pull request or project docs.
