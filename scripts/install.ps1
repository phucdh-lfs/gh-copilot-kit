[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$Profile = '',
    [string]$PromptsRoot = $(if ($env:COPILOT_USER_PROMPTS_DIR) { $env:COPILOT_USER_PROMPTS_DIR } else { Join-Path $env:APPDATA 'Code\User\prompts' }),
    [string]$SkillsRoot = $(if ($env:COPILOT_SKILLS_DIR) { $env:COPILOT_SKILLS_DIR } else { Join-Path $HOME '.copilot\skills' })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $PSScriptRoot
$InstructionsSrc = Join-Path $RootDir 'instructions'
$PromptsSrc = Join-Path $RootDir 'prompts'
$SkillsSrc = Join-Path $RootDir 'skills'
$ProfilesSrc = Join-Path $RootDir 'profiles'
$ProfileSrc = if ([string]::IsNullOrWhiteSpace($Profile)) { '' } else { Join-Path $ProfilesSrc $Profile }
$InstructionsDest = Join-Path $PromptsRoot 'instructions'
$PromptsDest = Join-Path $PromptsRoot 'prompts'
$Timestamp = Get-Date -Format 'yyyyMMddHHmmssfff'

function Invoke-KitAction {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    if ($DryRun) {
        Write-Host "DRY-RUN: $Message"
        return
    }

    & $Action
}

function Require-Directory {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Missing required directory: $Path"
    }
}

function Test-FrontmatterExists {
    param([Parameter(Mandatory = $true)][string]$Path)

    $Lines = Get-Content -LiteralPath $Path -TotalCount 200
    if ($Lines.Count -lt 2) {
        return $false
    }

    return $Lines[0] -eq '---' -and ($Lines[1..($Lines.Count - 1)] -contains '---')
}

function Get-SkillName {
    param([Parameter(Mandatory = $true)][string]$Path)

    $Lines = Get-Content -LiteralPath $Path -TotalCount 80
    foreach ($Line in $Lines) {
        if ($Line -match '^name:\s*["'']?([^"'']+)["'']?\s*$') {
            return $Matches[1].Trim()
        }
    }
    return $null
}

function Test-FrontmatterHasKey {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $Lines = Get-Content -LiteralPath $Path -TotalCount 80
    if ($Lines.Count -lt 2) {
        return $false
    }
    foreach ($Line in $Lines[1..($Lines.Count - 1)]) {
        if ($Line -eq '---') {
            return $false
        }
        if ($Line -match "^$([regex]::Escape($Key))\s*:") {
            return $true
        }
    }
    return $false
}

function Validate-Sources {
    Require-Directory $InstructionsSrc
    Require-Directory $SkillsSrc

    foreach ($File in Get-ChildItem -LiteralPath $InstructionsSrc -File) {
        if ($File.Name -notlike '*.instructions.md') {
            throw "Instruction file must end with .instructions.md: $($File.FullName)"
        }
        if (-not (Test-FrontmatterExists $File.FullName)) {
            throw "Missing YAML frontmatter delimiters: $($File.FullName)"
        }
    }

    if (Test-Path -LiteralPath $PromptsSrc -PathType Container) {
        foreach ($File in Get-ChildItem -LiteralPath $PromptsSrc -File) {
            if ($File.Name -notlike '*.prompt.md') {
                throw "Prompt file must end with .prompt.md: $($File.FullName)"
            }
            if (-not (Test-FrontmatterExists $File.FullName)) {
                throw "Missing YAML frontmatter delimiters: $($File.FullName)"
            }
            if (Test-FrontmatterHasKey $File.FullName 'agent') {
                throw "Prompt frontmatter uses deprecated key ""agent""; use ""mode"" instead: $($File.FullName)"
            }
        }
    }

    foreach ($SkillDir in Get-ChildItem -LiteralPath $SkillsSrc -Directory) {
        $SkillFile = Join-Path $SkillDir.FullName 'SKILL.md'
        if (-not (Test-Path -LiteralPath $SkillFile -PathType Leaf)) {
            throw "Missing SKILL.md in skill folder: $($SkillDir.FullName)"
        }
        if (-not (Test-FrontmatterExists $SkillFile)) {
            throw "Missing YAML frontmatter delimiters: $SkillFile"
        }
        $SkillName = Get-SkillName $SkillFile
        if ([string]::IsNullOrWhiteSpace($SkillName)) {
            throw "Missing skill name in: $SkillFile"
        }
        if ($SkillName -ne $SkillDir.Name) {
            throw "Skill folder/name mismatch: folder=$($SkillDir.Name) name=$SkillName"
        }
        if ($SkillName -notmatch '^[a-z0-9][a-z0-9-]{0,63}$') {
            throw "Invalid skill name: $SkillName"
        }
    }
}

function Validate-ProfileSources {
    param([Parameter(Mandatory = $true)][string]$ProfileRoot)

    Require-Directory $ProfileRoot

    $ProfileInstructions = Join-Path $ProfileRoot 'instructions'
    $ProfilePrompts = Join-Path $ProfileRoot 'prompts'
    $ProfileSkills = Join-Path $ProfileRoot 'skills'

    if (Test-Path -LiteralPath $ProfileInstructions -PathType Container) {
        foreach ($File in Get-ChildItem -LiteralPath $ProfileInstructions -File) {
            if ($File.Name -notlike '*.instructions.md') {
                throw "Instruction file must end with .instructions.md: $($File.FullName)"
            }
            if (-not (Test-FrontmatterExists $File.FullName)) {
                throw "Missing YAML frontmatter delimiters: $($File.FullName)"
            }
        }
    }

    if (Test-Path -LiteralPath $ProfilePrompts -PathType Container) {
        foreach ($File in Get-ChildItem -LiteralPath $ProfilePrompts -File) {
            if ($File.Name -notlike '*.prompt.md') {
                throw "Prompt file must end with .prompt.md: $($File.FullName)"
            }
            if (-not (Test-FrontmatterExists $File.FullName)) {
                throw "Missing YAML frontmatter delimiters: $($File.FullName)"
            }
            if (Test-FrontmatterHasKey $File.FullName 'agent') {
                throw "Prompt frontmatter uses deprecated key ""agent""; use ""mode"" instead: $($File.FullName)"
            }
        }
    }

    if (Test-Path -LiteralPath $ProfileSkills -PathType Container) {
        foreach ($SkillDir in Get-ChildItem -LiteralPath $ProfileSkills -Directory) {
            $SkillFile = Join-Path $SkillDir.FullName 'SKILL.md'
            if (-not (Test-Path -LiteralPath $SkillFile -PathType Leaf)) {
                throw "Missing SKILL.md in skill folder: $($SkillDir.FullName)"
            }
            if (-not (Test-FrontmatterExists $SkillFile)) {
                throw "Missing YAML frontmatter delimiters: $SkillFile"
            }
            $SkillName = Get-SkillName $SkillFile
            if ([string]::IsNullOrWhiteSpace($SkillName)) {
                throw "Missing skill name in: $SkillFile"
            }
            if ($SkillName -ne $SkillDir.Name) {
                throw "Skill folder/name mismatch: folder=$($SkillDir.Name) name=$SkillName"
            }
            if ($SkillName -notmatch '^[a-z0-9][a-z0-9-]{0,63}$') {
                throw "Invalid skill name: $SkillName"
            }
        }
    }
}

function Ensure-ParentWritable {
    param([Parameter(Mandatory = $true)][string]$Path)

    $Parent = Split-Path -Parent $Path
    if (Test-Path -LiteralPath $Parent) {
        $Probe = Join-Path $Parent ".copilot-kit-write-test.$PID"
        try {
            Set-Content -LiteralPath $Probe -Value '' -NoNewline
            Remove-Item -LiteralPath $Probe -Force
        } catch {
            throw "Destination parent is not writable: $Parent"
        }
    }
}

function Backup-IfExists {
    param([Parameter(Mandatory = $true)][string]$Destination)

    if (Test-Path -LiteralPath $Destination) {
        $Backup = "$Destination.backup.$Timestamp"
        Invoke-KitAction "Move $Destination to $Backup" { Move-Item -LiteralPath $Destination -Destination $Backup }
    }
}

function Copy-KitFile {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    Ensure-ParentWritable $Destination
    $Parent = Split-Path -Parent $Destination
    Invoke-KitAction "Create directory $Parent" { New-Item -ItemType Directory -Force -Path $Parent | Out-Null }
    Backup-IfExists $Destination
    Invoke-KitAction "Copy $Source to $Destination" { Copy-Item -LiteralPath $Source -Destination $Destination }
}

function Copy-KitDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    Ensure-ParentWritable $Destination
    $Parent = Split-Path -Parent $Destination
    Invoke-KitAction "Create directory $Parent" { New-Item -ItemType Directory -Force -Path $Parent | Out-Null }
    Backup-IfExists $Destination
    Invoke-KitAction "Copy $Source to $Destination" { Copy-Item -LiteralPath $Source -Destination $Destination -Recurse }
}

Write-Verbose "Repository root: $RootDir"
Write-Verbose "Profile: $(if ([string]::IsNullOrWhiteSpace($Profile)) { 'none' } else { $Profile })"
Write-Verbose "Prompts root: $PromptsRoot"
Write-Verbose "Skills root: $SkillsRoot"

Validate-Sources
if (-not [string]::IsNullOrWhiteSpace($Profile)) {
    Validate-ProfileSources $ProfileSrc
}

foreach ($File in Get-ChildItem -LiteralPath $InstructionsSrc -File -Filter '*.instructions.md') {
    Copy-KitFile $File.FullName (Join-Path $InstructionsDest $File.Name)
}

if (Test-Path -LiteralPath $PromptsSrc -PathType Container) {
    foreach ($File in Get-ChildItem -LiteralPath $PromptsSrc -File -Filter '*.prompt.md') {
        Copy-KitFile $File.FullName (Join-Path $PromptsDest $File.Name)
    }
}

foreach ($SkillDir in Get-ChildItem -LiteralPath $SkillsSrc -Directory) {
    Copy-KitDirectory $SkillDir.FullName (Join-Path $SkillsRoot $SkillDir.Name)
}

if (-not [string]::IsNullOrWhiteSpace($Profile)) {
    $ProfileInstructions = Join-Path $ProfileSrc 'instructions'
    $ProfilePrompts = Join-Path $ProfileSrc 'prompts'
    $ProfileSkills = Join-Path $ProfileSrc 'skills'

    if (Test-Path -LiteralPath $ProfileInstructions -PathType Container) {
        foreach ($File in Get-ChildItem -LiteralPath $ProfileInstructions -File -Filter '*.instructions.md') {
            Copy-KitFile $File.FullName (Join-Path $InstructionsDest $File.Name)
        }
    }

    if (Test-Path -LiteralPath $ProfilePrompts -PathType Container) {
        foreach ($File in Get-ChildItem -LiteralPath $ProfilePrompts -File -Filter '*.prompt.md') {
            Copy-KitFile $File.FullName (Join-Path $PromptsDest $File.Name)
        }
    }

    if (Test-Path -LiteralPath $ProfileSkills -PathType Container) {
        foreach ($SkillDir in Get-ChildItem -LiteralPath $ProfileSkills -Directory) {
            Copy-KitDirectory $SkillDir.FullName (Join-Path $SkillsRoot $SkillDir.Name)
        }
    }
}

if ($DryRun) {
    Write-Host 'Dry run complete. No files were changed.'
} else {
    Write-Host 'Copilot team kit installed successfully. Restart VS Code if new prompts or skills are not visible.'
}
