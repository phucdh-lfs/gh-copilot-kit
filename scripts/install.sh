#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPTS_ROOT="${COPILOT_USER_PROMPTS_DIR:-$HOME/Library/Application Support/Code/User/prompts}"
SKILLS_ROOT="${COPILOT_SKILLS_DIR:-$HOME/.copilot/skills}"
DRY_RUN=0
VERBOSE=0
TIMESTAMP="$(date +%Y%m%d%H%M%S)-$$"

usage() {
  cat <<'USAGE'
Usage: scripts/install.sh [options]

Options:
  --dry-run                 Print actions without changing files
  --verbose                 Print resolved paths and copy operations
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

INSTRUCTIONS_SRC="$ROOT_DIR/instructions"
PROMPTS_SRC="$ROOT_DIR/prompts"
SKILLS_SRC="$ROOT_DIR/skills"
INSTRUCTIONS_DEST="$PROMPTS_ROOT/instructions"
PROMPTS_DEST="$PROMPTS_ROOT/prompts"

require_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    log "Missing required directory: $path"
    exit 1
  fi
}

frontmatter_exists() {
  local file="$1"
  [[ "$(sed -n '1p' "$file")" == '---' ]] && grep -q '^---$' <(sed -n '2,$p' "$file")
}

extract_skill_name() {
  local file="$1"
  sed -n '1,/^---$/p' "$file" | sed -n 's/^name:[[:space:]]*['\''"]\{0,1\}\([^'\''"]*\)['\''"]\{0,1\}[[:space:]]*$/\1/p' | head -n 1
}

frontmatter_has_key() {
  local file="$1"
  local key="$2"
  sed -n '1,/^---$/p' "$file" | grep -Eq "^${key}[[:space:]]*:"
}

validate_sources() {
  require_dir "$INSTRUCTIONS_SRC"
  require_dir "$PROMPTS_SRC"
  require_dir "$SKILLS_SRC"

  local file
  while IFS= read -r -d '' file; do
    case "$file" in
      *.instructions.md) ;;
      *) log "Instruction file must end with .instructions.md: $file"; exit 1 ;;
    esac
    if ! frontmatter_exists "$file"; then
      log "Missing YAML frontmatter delimiters: $file"
      exit 1
    fi
  done < <(find "$INSTRUCTIONS_SRC" -maxdepth 1 -type f -print0)

  while IFS= read -r -d '' file; do
    case "$file" in
      *.prompt.md) ;;
      *) log "Prompt file must end with .prompt.md: $file"; exit 1 ;;
    esac
    if ! frontmatter_exists "$file"; then
      log "Missing YAML frontmatter delimiters: $file"
      exit 1
    fi
    if frontmatter_has_key "$file" 'agent'; then
      log "Prompt frontmatter uses deprecated key \"agent\"; use \"mode\" instead: $file"
      exit 1
    fi
  done < <(find "$PROMPTS_SRC" -maxdepth 1 -type f -print0)

  local skill_dir skill_file folder_name skill_name
  while IFS= read -r -d '' skill_dir; do
    skill_file="$skill_dir/SKILL.md"
    folder_name="$(basename "$skill_dir")"
    if [[ ! -f "$skill_file" ]]; then
      log "Missing SKILL.md in skill folder: $skill_dir"
      exit 1
    fi
    if ! frontmatter_exists "$skill_file"; then
      log "Missing YAML frontmatter delimiters: $skill_file"
      exit 1
    fi
    skill_name="$(extract_skill_name "$skill_file")"
    if [[ -z "$skill_name" ]]; then
      log "Missing skill name in: $skill_file"
      exit 1
    fi
    if [[ "$skill_name" != "$folder_name" ]]; then
      log "Skill folder/name mismatch: folder=$folder_name name=$skill_name"
      exit 1
    fi
    if [[ ! "$skill_name" =~ ^[a-z0-9][a-z0-9-]{0,63}$ ]]; then
      log "Invalid skill name: $skill_name"
      exit 1
    fi
  done < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d -print0)
}

ensure_parent_writable() {
  local path="$1"
  local parent
  parent="$(dirname "$path")"
  if [[ -e "$parent" && ! -w "$parent" ]]; then
    log "Destination parent is not writable: $parent"
    exit 1
  fi
}

backup_if_exists() {
  local destination="$1"
  if [[ -e "$destination" ]]; then
    local backup="$destination.backup.$TIMESTAMP"
    verbose "Backing up $destination to $backup"
    run mv "$destination" "$backup"
  fi
}

copy_file() {
  local source="$1"
  local destination="$2"
  ensure_parent_writable "$destination"
  run mkdir -p "$(dirname "$destination")"
  backup_if_exists "$destination"
  verbose "Copying $source to $destination"
  run cp "$source" "$destination"
}

copy_dir() {
  local source="$1"
  local destination="$2"
  ensure_parent_writable "$destination"
  run mkdir -p "$(dirname "$destination")"
  backup_if_exists "$destination"
  verbose "Copying $source to $destination"
  run cp -R "$source" "$destination"
}

main() {
  verbose "Repository root: $ROOT_DIR"
  verbose "Prompts root: $PROMPTS_ROOT"
  verbose "Skills root: $SKILLS_ROOT"

  validate_sources

  local file skill_dir name
  while IFS= read -r -d '' file; do
    copy_file "$file" "$INSTRUCTIONS_DEST/$(basename "$file")"
  done < <(find "$INSTRUCTIONS_SRC" -maxdepth 1 -type f -name '*.instructions.md' -print0)

  while IFS= read -r -d '' file; do
    copy_file "$file" "$PROMPTS_DEST/$(basename "$file")"
  done < <(find "$PROMPTS_SRC" -maxdepth 1 -type f -name '*.prompt.md' -print0)

  while IFS= read -r -d '' skill_dir; do
    name="$(basename "$skill_dir")"
    copy_dir "$skill_dir" "$SKILLS_ROOT/$name"
  done < <(find "$SKILLS_SRC" -mindepth 1 -maxdepth 1 -type d -print0)

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry run complete. No files were changed."
  else
    log "Copilot team kit installed successfully. Restart VS Code if new prompts or skills are not visible."
  fi
}

main
