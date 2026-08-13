# GitHub Copilot Team Kit

Team-wide GitHub Copilot customizations that developers can install into their global VS Code/Copilot profile after cloning this repository.

This kit currently installs:

- Instructions from `instructions/*.instructions.md`
- Skills from `skills/<skill-name>/SKILL.md`
- Optional profile overlays from `profiles/<profile-name>/`

The installers back up existing same-name global files before overwriting them.

## Install

### macOS

```sh
bash scripts/install.sh --dry-run --verbose
bash scripts/install.sh --verbose
bash scripts/install.sh --profile developer --verbose
bash scripts/install.sh --profile tester --verbose
```

### Windows PowerShell

```powershell
pwsh ./scripts/install.ps1 -DryRun -Verbose
pwsh ./scripts/install.ps1 -Verbose
pwsh ./scripts/install.ps1 -Profile developer -Verbose
pwsh ./scripts/install.ps1 -Profile tester -Verbose
```

## Profiles

Profiles install the common kit assets first, then overlay role-specific assets from `profiles/<profile-name>/`.

Available profiles:

- `developer`: implementation, refactoring, debugging, and maintenance guidance
- `tester`: test planning, validation, regression analysis, and quality review guidance

Switch profiles by rerunning the installer with another profile name. Existing same-name global files are backed up before replacement.

## Uninstall

Uninstall removes the exact asset names provided by this repository, including profile overlay assets. It does not remove unrelated user customizations or `.backup.*` files.

macOS/Linux shell:

```sh
bash scripts/uninstall.sh --dry-run --verbose
bash scripts/uninstall.sh --verbose
```

PowerShell:

```powershell
pwsh ./scripts/uninstall.ps1 -DryRun -Verbose
pwsh ./scripts/uninstall.ps1 -Verbose
```

## Installed Locations

### macOS

- Instructions: `~/Library/Application Support/Code/User/prompts/instructions`
- Skills: `~/.copilot/skills`

### Windows

- Instructions: `%APPDATA%\Code\User\prompts\instructions`
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
- Prompt files use `.prompt.md` when a `prompts/` folder is present
- All customization files have YAML frontmatter delimiters
- Skill folder names match the `name` in `SKILL.md`
- Skill names use lowercase letters, numbers, and hyphens
- Profile overlays follow the same file and frontmatter rules

## Adding Team Assets

Use `instructions/` for guidance that should influence coding behavior across many tasks. Use narrow `applyTo` globs when the guidance is file-specific.

Use `skills/` for repeatable actions and multi-step workflows, especially when they include procedures, scripts, templates, or references.

Keep descriptions keyword-rich. Copilot uses descriptions as the discovery surface when deciding what to load.
