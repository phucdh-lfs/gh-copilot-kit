# Contributing

## Choose The Right Asset

- Instructions: coding standards, review preferences, architecture constraints, and file-pattern-specific guidance.
- Skills: multi-step workflows, especially when they include scripts, templates, references, or decision procedures.

## Naming

- Instruction files: `kebab-case.instructions.md`
- Skill folders: `kebab-case`
- Skill `name`: must exactly match the folder name

## Frontmatter Checklist

Every customization file should start and end frontmatter with `---`.

Instructions should include:

```yaml
---
description: "Use when..."
applyTo: "**/*.ts"
---
```

Skills should include:

```yaml
---
name: skill-name
description: "Use when..."
---
```

## Review Checklist

- The description includes the words a teammate would naturally use.
- The content is concise enough to fit in model context.
- The asset does not duplicate long project documentation.
- `applyTo` is scoped narrowly unless the instruction truly applies everywhere.
- Installers and validation scripts pass on changed assets.
