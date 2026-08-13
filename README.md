# GitHub Copilot Team Kit

Team-wide GitHub Copilot customizations that developers can install into their global VS Code/Copilot profile after cloning this repository.

This kit currently installs:

- Instructions from `instructions/*.instructions.md`
- Prompt files from `prompts/*.prompt.md`
- Skills from `skills/<skill-name>/SKILL.md`

The installers back up existing same-name global files before overwriting them.

## Install

### macOS

```sh
bash scripts/install.sh --dry-run --verbose
bash scripts/install.sh --verbose
```

### Windows PowerShell

```powershell
pwsh ./scripts/install.ps1 -DryRun -Verbose
pwsh ./scripts/install.ps1 -Verbose
```

## Installed Locations

### macOS

- Instructions: `~/Library/Application Support/Code/User/prompts/instructions`
- Prompts: `~/Library/Application Support/Code/User/prompts/prompts`
- Skills: `~/.copilot/skills`

### Windows

- Instructions: `%APPDATA%\Code\User\prompts\instructions`
- Prompts: `%APPDATA%\Code\User\prompts\prompts`
- Skills: `%USERPROFILE%\.copilot\skills`

## Custom Paths

Use custom paths when your team uses VS Code Insiders, portable installs, or managed profiles.

macOS/Linux shell:

```sh
bash scripts/install.sh --prompts-root "$HOME/Library/Application Support/Code - Insiders/User/prompts"
bash scripts/install.sh --skills-root "$HOME/.copilot/skills"
```

PowerShell:

```powershell
pwsh ./scripts/install.ps1 -PromptsRoot "$env:APPDATA\Code - Insiders\User\prompts"
pwsh ./scripts/install.ps1 -SkillsRoot "$HOME\.copilot\skills"
```

## Updating

Pull the latest repository changes and rerun the installer.

```sh
git pull
bash scripts/install.sh --verbose
```

Existing global files with matching names are moved aside first using a `.backup.<timestamp>` suffix.

## Validate The Kit

Run validation before opening a pull request:

```sh
bash scripts/validate-kit.sh
pwsh ./scripts/validate-kit.ps1
```

Validation checks that:

- Instruction files use `.instructions.md`
- Prompt files use `.prompt.md`
- All customization files have YAML frontmatter delimiters
- Skill folder names match the `name` in `SKILL.md`
- Skill names use lowercase letters, numbers, and hyphens

## Adding Team Assets

Use `instructions/` for guidance that should influence coding behavior across many tasks. Use narrow `applyTo` globs when the guidance is file-specific.

Use `prompts/` for one focused repeatable action, such as producing a review checklist or creating a test plan.

Use `skills/` for multi-step workflows with bundled procedures, scripts, templates, or references.

Keep descriptions keyword-rich. Copilot uses descriptions as the discovery surface when deciding what to load.
