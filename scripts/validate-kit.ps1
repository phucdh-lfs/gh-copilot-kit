[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $PSScriptRoot
$InstructionsSrc = Join-Path $RootDir 'instructions'
$PromptsSrc = Join-Path $RootDir 'prompts'
$SkillsSrc = Join-Path $RootDir 'skills'
$ProfilesSrc = Join-Path $RootDir 'profiles'

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

function Validate-AssetRoot {
    param(
        [Parameter(Mandatory = $true)][string]$AssetRoot,
        [Parameter(Mandatory = $true)][bool]$RequireAll
    )

    $InstructionsRoot = Join-Path $AssetRoot 'instructions'
    $PromptsRoot = Join-Path $AssetRoot 'prompts'
    $SkillsRoot = Join-Path $AssetRoot 'skills'

    if ($RequireAll) {
        Require-Directory $InstructionsRoot
        Require-Directory $SkillsRoot
    }

    if (Test-Path -LiteralPath $InstructionsRoot -PathType Container) {
        foreach ($File in Get-ChildItem -LiteralPath $InstructionsRoot -File) {
            if ($File.Name -notlike '*.instructions.md') {
                throw "Instruction file must end with .instructions.md: $($File.FullName)"
            }
            if (-not (Test-FrontmatterExists $File.FullName)) {
                throw "Missing YAML frontmatter delimiters: $($File.FullName)"
            }
        }
    }

    if (Test-Path -LiteralPath $PromptsRoot -PathType Container) {
        foreach ($File in Get-ChildItem -LiteralPath $PromptsRoot -File) {
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

    if (Test-Path -LiteralPath $SkillsRoot -PathType Container) {
        foreach ($SkillDir in Get-ChildItem -LiteralPath $SkillsRoot -Directory) {
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

Validate-AssetRoot $RootDir $true

if (Test-Path -LiteralPath $ProfilesSrc -PathType Container) {
    foreach ($ProfileRoot in Get-ChildItem -LiteralPath $ProfilesSrc -Directory) {
        Validate-AssetRoot $ProfileRoot.FullName $false
    }
}

Write-Host 'Copilot team kit validation passed.'
