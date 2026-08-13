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

validate_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    printf 'Missing required directory: %s\n' "$path" >&2
    exit 1
  fi
}

validate_dir "$ROOT_DIR/instructions"
validate_dir "$ROOT_DIR/prompts"
validate_dir "$ROOT_DIR/skills"

while IFS= read -r -d '' file; do
  case "$file" in
    *.instructions.md) ;;
    *) printf 'Instruction file must end with .instructions.md: %s\n' "$file" >&2; exit 1 ;;
  esac
  frontmatter_exists "$file" || { printf 'Missing YAML frontmatter delimiters: %s\n' "$file" >&2; exit 1; }
done < <(find "$ROOT_DIR/instructions" -maxdepth 1 -type f -print0)

while IFS= read -r -d '' file; do
  case "$file" in
    *.prompt.md) ;;
    *) printf 'Prompt file must end with .prompt.md: %s\n' "$file" >&2; exit 1 ;;
  esac
  frontmatter_exists "$file" || { printf 'Missing YAML frontmatter delimiters: %s\n' "$file" >&2; exit 1; }
done < <(find "$ROOT_DIR/prompts" -maxdepth 1 -type f -print0)

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
done < <(find "$ROOT_DIR/skills" -mindepth 1 -maxdepth 1 -type d -print0)

printf 'Copilot team kit validation passed.\n'
