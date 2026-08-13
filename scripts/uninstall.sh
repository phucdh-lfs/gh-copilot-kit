#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPTS_ROOT="${COPILOT_USER_PROMPTS_DIR:-$HOME/Library/Application Support/Code/User/prompts}"
SKILLS_ROOT="${COPILOT_SKILLS_DIR:-$HOME/.copilot/skills}"
DRY_RUN=0
VERBOSE=0

usage() {
  cat <<'USAGE'
Usage: scripts/uninstall.sh [options]

Options:
  --dry-run                 Print actions without changing files
  --verbose                 Print resolved paths and remove operations
  --prompts-root PATH       Override VS Code user prompts root
  --skills-root PATH        Override Copilot skills root
  -h, --help                Show this help

Environment overrides:
  COPILOT_USER_PROMPTS_DIR  VS Code user prompts root
  COPILOT_SKILLS_DIR        Copilot skills root
USAGE
}

log() {
  printf '%s\n' "$*"
}

verbose() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    log "$@"
  fi
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY-RUN: $*"
  else
    "$@"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --verbose)
      VERBOSE=1
      shift
      ;;
    --prompts-root)
      PROMPTS_ROOT="${2:?Missing value for --prompts-root}"
      shift 2
      ;;
    --skills-root)
      SKILLS_ROOT="${2:?Missing value for --skills-root}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      log "Unknown option: $1"
      usage
      exit 2
      ;;
  esac
done

INSTRUCTIONS_DEST="$PROMPTS_ROOT/instructions"
PROMPTS_DEST="$PROMPTS_ROOT/prompts"

remove_path() {
  local path="$1"
  if [[ -e "$path" ]]; then
    verbose "Removing $path"
    run rm -rf "$path"
  else
    verbose "Skipping missing $path"
  fi
}

remove_instruction_file() {
  local source="$1"
  remove_path "$INSTRUCTIONS_DEST/$(basename "$source")"
}

remove_prompt_file() {
  local source="$1"
  remove_path "$PROMPTS_DEST/$(basename "$source")"
}

remove_skill_dir() {
  local source="$1"
  remove_path "$SKILLS_ROOT/$(basename "$source")"
}

remove_from_asset_root() {
  local asset_root="$1"

  if [[ -d "$asset_root/instructions" ]]; then
    while IFS= read -r -d '' file; do
      remove_instruction_file "$file"
    done < <(find "$asset_root/instructions" -maxdepth 1 -type f -name '*.instructions.md' -print0)
  fi

  if [[ -d "$asset_root/prompts" ]]; then
    while IFS= read -r -d '' file; do
      remove_prompt_file "$file"
    done < <(find "$asset_root/prompts" -maxdepth 1 -type f -name '*.prompt.md' -print0)
  fi

  if [[ -d "$asset_root/skills" ]]; then
    while IFS= read -r -d '' skill_dir; do
      remove_skill_dir "$skill_dir"
    done < <(find "$asset_root/skills" -mindepth 1 -maxdepth 1 -type d -print0)
  fi
}

main() {
  verbose "Repository root: $ROOT_DIR"
  verbose "Prompts root: $PROMPTS_ROOT"
  verbose "Skills root: $SKILLS_ROOT"

  remove_from_asset_root "$ROOT_DIR"

  if [[ -d "$ROOT_DIR/profiles" ]]; then
    while IFS= read -r -d '' profile_root; do
      remove_from_asset_root "$profile_root"
    done < <(find "$ROOT_DIR/profiles" -mindepth 1 -maxdepth 1 -type d -print0)
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry run complete. No files were changed."
  else
    log "Copilot team kit uninstalled successfully. Restart VS Code if removed prompts or skills are still visible."
  fi
}

main
