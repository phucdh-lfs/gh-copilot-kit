[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$PromptsRoot = $(if ($env:COPILOT_USER_PROMPTS_DIR) { $env:COPILOT_USER_PROMPTS_DIR } else { Join-Path $env:APPDATA 'Code\User\prompts' }),
    [string]$SkillsRoot = $(if ($env:COPILOT_SKILLS_DIR) { $env:COPILOT_SKILLS_DIR } else { Join-Path $HOME '.copilot\skills' })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RootDir = Split-Path -Parent $PSScriptRoot
$InstructionsDest = Join-Path $PromptsRoot 'instructions'
$PromptsDest = Join-Path $PromptsRoot 'prompts'

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

function Remove-KitPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Write-Verbose "Removing $Path"
        Invoke-KitAction "Remove $Path" { Remove-Item -LiteralPath $Path -Recurse -Force }
    } else {
        Write-Verbose "Skipping missing $Path"
    }
}

function Remove-InstructionFile {
    param([Parameter(Mandatory = $true)][string]$Source)

    Remove-KitPath (Join-Path $InstructionsDest (Split-Path -Leaf $Source))
}

function Remove-PromptFile {
    param([Parameter(Mandatory = $true)][string]$Source)

    Remove-KitPath (Join-Path $PromptsDest (Split-Path -Leaf $Source))
}

function Remove-SkillDirectory {
    param([Parameter(Mandatory = $true)][string]$Source)

    Remove-KitPath (Join-Path $SkillsRoot (Split-Path -Leaf $Source))
}

function Remove-FromAssetRoot {
    param([Parameter(Mandatory = $true)][string]$AssetRoot)

    $InstructionsRoot = Join-Path $AssetRoot 'instructions'
    $PromptsRootSource = Join-Path $AssetRoot 'prompts'
    $SkillsRootSource = Join-Path $AssetRoot 'skills'

    if (Test-Path -LiteralPath $InstructionsRoot -PathType Container) {
        foreach ($File in Get-ChildItem -LiteralPath $InstructionsRoot -File -Filter '*.instructions.md') {
            Remove-InstructionFile $File.FullName
        }
    }

    if (Test-Path -LiteralPath $PromptsRootSource -PathType Container) {
        foreach ($File in Get-ChildItem -LiteralPath $PromptsRootSource -File -Filter '*.prompt.md') {
            Remove-PromptFile $File.FullName
        }
    }

    if (Test-Path -LiteralPath $SkillsRootSource -PathType Container) {
        foreach ($SkillDir in Get-ChildItem -LiteralPath $SkillsRootSource -Directory) {
            Remove-SkillDirectory $SkillDir.FullName
        }
    }
}

Write-Verbose "Repository root: $RootDir"
Write-Verbose "Prompts root: $PromptsRoot"
Write-Verbose "Skills root: $SkillsRoot"

Remove-FromAssetRoot $RootDir

$ProfilesRoot = Join-Path $RootDir 'profiles'
if (Test-Path -LiteralPath $ProfilesRoot -PathType Container) {
    foreach ($ProfileRoot in Get-ChildItem -LiteralPath $ProfilesRoot -Directory) {
        Remove-FromAssetRoot $ProfileRoot.FullName
    }
}

if ($DryRun) {
    Write-Host 'Dry run complete. No files were changed.'
} else {
    Write-Host 'Copilot team kit uninstalled successfully. Restart VS Code if removed prompts or skills are still visible.'
}
