[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$PromptsRoot = $(if ($env:COPILOT_USER_PROMPTS_DIR) { $env:COPILOT_USER_PROMPTS_DIR } else { Join-Path $env:APPDATA 'Code\User\prompts' }),
    [string]$SkillsRoot = $(if ($env:COPILOT_SKILLS_DIR) { $env:COPILOT_SKILLS_DIR } else { Join-Path $HOME '.copilot\skills' })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $PSScriptRoot
$InstructionsSrc = Join-Path $RootDir 'instructions'
$PromptsSrc = Join-Path $RootDir 'prompts'
$SkillsSrc = Join-Path $RootDir 'skills'
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

function Validate-Sources {
    Require-Directory $InstructionsSrc
    Require-Directory $PromptsSrc
    Require-Directory $SkillsSrc

    foreach ($File in Get-ChildItem -LiteralPath $InstructionsSrc -File) {
        if ($File.Name -notlike '*.instructions.md') {
            throw "Instruction file must end with .instructions.md: $($File.FullName)"
        }
        if (-not (Test-FrontmatterExists $File.FullName)) {
            throw "Missing YAML frontmatter delimiters: $($File.FullName)"
        }
    }

    foreach ($File in Get-ChildItem -LiteralPath $PromptsSrc -File) {
        if ($File.Name -notlike '*.prompt.md') {
            throw "Prompt file must end with .prompt.md: $($File.FullName)"
        }
        if (-not (Test-FrontmatterExists $File.FullName)) {
            throw "Missing YAML frontmatter delimiters: $($File.FullName)"
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
Write-Verbose "Prompts root: $PromptsRoot"
Write-Verbose "Skills root: $SkillsRoot"

Validate-Sources

foreach ($File in Get-ChildItem -LiteralPath $InstructionsSrc -File -Filter '*.instructions.md') {
    Copy-KitFile $File.FullName (Join-Path $InstructionsDest $File.Name)
}

foreach ($File in Get-ChildItem -LiteralPath $PromptsSrc -File -Filter '*.prompt.md') {
    Copy-KitFile $File.FullName (Join-Path $PromptsDest $File.Name)
}

foreach ($SkillDir in Get-ChildItem -LiteralPath $SkillsSrc -Directory) {
    Copy-KitDirectory $SkillDir.FullName (Join-Path $SkillsRoot $SkillDir.Name)
}

if ($DryRun) {
    Write-Host 'Dry run complete. No files were changed.'
} else {
    Write-Host 'Copilot team kit installed successfully. Restart VS Code if new prompts or skills are not visible.'
}
