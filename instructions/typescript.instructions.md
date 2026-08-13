---
description: "Use when working on TypeScript, JavaScript, React, Node.js, package scripts, or frontend build tooling."
applyTo: ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx", "package.json"]
---
# TypeScript And JavaScript Guidance

- Prefer the project's existing TypeScript configuration and lint rules over introducing local exceptions.
- Keep runtime behavior explicit when changing types; do not use `any` to silence errors without a clear reason.
- Use existing shared helpers, client libraries, and component patterns before adding new utilities.
- For React changes, preserve established state management and data fetching patterns.
- Add or update focused tests when changing user-visible behavior, data transformations, or API contracts.
