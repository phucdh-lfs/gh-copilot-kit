[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $PSScriptRoot
$InstructionsSrc = Join-Path $RootDir 'instructions'
$PromptsSrc = Join-Path $RootDir 'prompts'
$SkillsSrc = Join-Path $RootDir 'skills'

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

Write-Host 'Copilot team kit validation passed.'
