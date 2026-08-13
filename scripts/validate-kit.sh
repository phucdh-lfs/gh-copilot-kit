#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

validate_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    printf 'Missing required directory: %s\n' "$path" >&2
    exit 1
  fi
}

validate_asset_root() {
  local asset_root="$1"
  local require_all="$2"
  local instructions_root="$asset_root/instructions"
  local prompts_root="$asset_root/prompts"
  local skills_root="$asset_root/skills"
  local file skill_dir skill_file folder_name skill_name

  if [[ "$require_all" -eq 1 ]]; then
    validate_dir "$instructions_root"
    validate_dir "$skills_root"
  fi

  if [[ -d "$instructions_root" ]]; then
    while IFS= read -r -d '' file; do
      case "$file" in
        *.instructions.md) ;;
        *) printf 'Instruction file must end with .instructions.md: %s\n' "$file" >&2; exit 1 ;;
      esac
      frontmatter_exists "$file" || { printf 'Missing YAML frontmatter delimiters: %s\n' "$file" >&2; exit 1; }
    done < <(find "$instructions_root" -maxdepth 1 -type f -print0)
  fi

  if [[ -d "$prompts_root" ]]; then
    while IFS= read -r -d '' file; do
      case "$file" in
        *.prompt.md) ;;
        *) printf 'Prompt file must end with .prompt.md: %s\n' "$file" >&2; exit 1 ;;
      esac
      frontmatter_exists "$file" || { printf 'Missing YAML frontmatter delimiters: %s\n' "$file" >&2; exit 1; }
      frontmatter_has_key "$file" 'agent' && { printf 'Prompt frontmatter uses deprecated key "agent"; use "mode" instead: %s\n' "$file" >&2; exit 1; }
    done < <(find "$prompts_root" -maxdepth 1 -type f -print0)
  fi

  if [[ -d "$skills_root" ]]; then
    while IFS= read -r -d '' skill_dir; do
      skill_file="$skill_dir/SKILL.md"
      folder_name="$(basename "$skill_dir")"
      if [[ ! -f "$skill_file" ]]; then
        printf 'Missing SKILL.md in skill folder: %s\n' "$skill_dir" >&2
        exit 1
      fi
      frontmatter_exists "$skill_file" || { printf 'Missing YAML frontmatter delimiters: %s\n' "$skill_file" >&2; exit 1; }
      skill_name="$(extract_skill_name "$skill_file")"
      if [[ -z "$skill_name" ]]; then
        printf 'Missing skill name in: %s\n' "$skill_file" >&2
        exit 1
      fi
      if [[ "$skill_name" != "$folder_name" ]]; then
        printf 'Skill folder/name mismatch: folder=%s name=%s\n' "$folder_name" "$skill_name" >&2
        exit 1
      fi
      if [[ ! "$skill_name" =~ ^[a-z0-9][a-z0-9-]{0,63}$ ]]; then
        printf 'Invalid skill name: %s\n' "$skill_name" >&2
        exit 1
      fi
    done < <(find "$skills_root" -mindepth 1 -maxdepth 1 -type d -print0)
  fi
}

validate_asset_root "$ROOT_DIR" 1

if [[ -d "$ROOT_DIR/profiles" ]]; then
  while IFS= read -r -d '' profile_root; do
    validate_asset_root "$profile_root" 0
  done < <(find "$ROOT_DIR/profiles" -mindepth 1 -maxdepth 1 -type d -print0)
fi

printf 'Copilot team kit validation passed.\n'
