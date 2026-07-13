#!/usr/bin/env bash
# Collector for bold.plan init's Migrate path. Inventories a DevSpark
# install so the migration report prompt reasons over structured ground
# truth instead of re-deriving it by hand.
#
# Learned from the TailwindSpark migration (2026-07-09, bold-tool-plan.md
# §15 crucible feedback): a real DevSpark repo accumulates far more than
# the predefined slots below -- guides, ADRs, release history, repo-story,
# legacy per-host adapter files, editor config referencing DevSpark. This
# collector now also emits a generic catch-all inventory of anything under
# .documentation/ it doesn't specifically recognize, detects a pre-existing
# root .archive/ (a real repo may already have one, worth adopting rather
# than treating as a conflict), counts legacy per-host adapter files, and
# scans tracked files for lingering "devspark" text references. It still
# doesn't *classify* any of this -- that's the migration report's job
# (Reason), not the collector's (Collect) -- it just makes sure nothing is
# silently invisible.
set -euo pipefail

root_override=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root) root_override="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -n "$root_override" ]; then
  repo_root="$root_override"
else
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib/common.sh
source "$script_dir/lib/common.sh"

entry_type_and_count() {
  # $1 = path -> prints "type\tfile_count"
  if [ -d "$1" ]; then
    printf 'dir\t%s' "$(find "$1" -type f | wc -l | tr -d ' ')"
  else
    printf 'file\t1'
  fi
}

devspark_dir="$repo_root/.devspark"
has_devspark_dir=false
devspark_file_count=0
if [ -d "$devspark_dir" ]; then
  has_devspark_dir=true
  devspark_file_count="$(find "$devspark_dir" -type f | wc -l | tr -d ' ')"
fi

docs_dir="$repo_root/.documentation"
has_documentation_dir=false
[ -d "$docs_dir" ] && has_documentation_dir=true

constitution_path="$docs_dir/memory/constitution.md"
has_constitution=false
principle_count=0
if [ -f "$constitution_path" ]; then
  has_constitution=true
  principle_count="$(awk '
    /^## Core Principles/ { in_section=1; next }
    in_section && /^## / { exit }
    in_section && /^### / { count++ }
    END { print count+0 }
  ' "$constitution_path")"
fi

team_scripts_dir="$docs_dir/scripts"
has_team_scripts_override=false
bold_scripts_dir="$repo_root/.bold/scripts"
bold_scripts_present=false
[ -d "$bold_scripts_dir" ] && bold_scripts_present=true
# Per carried script: would three-tier resolution ever serve it? An override
# is live only at an exact relative-path match against .bold/scripts/
# (bold-which's rule), so this is measurable -- the prompt must never
# re-derive it (issue #2: 15 dead scripts sat unflagged in a migrated repo).
team_script_entries=()
if [ -d "$team_scripts_dir" ]; then
  has_team_scripts_override=true
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="${f#"$team_scripts_dir"/}"
    resolves=false
    [ -f "$bold_scripts_dir/$rel" ] && resolves=true
    team_script_entries+=("{\"path\":\"$(json_escape "$rel")\",\"resolves_against_bold\":$resolves}")
  done < <(find "$team_scripts_dir" -type f | LC_ALL=C sort)
fi
team_scripts_json="[$(IFS=,; echo "${team_script_entries[*]}")]"
[ "${#team_script_entries[@]}" -eq 0 ] && team_scripts_json="[]"

specs_dir="$docs_dir/specs"
spec_entries=()
if [ -d "$specs_dir" ]; then
  while IFS= read -r dir; do
    [ -n "$dir" ] || continue
    name="$(basename "$dir")"
    count="$(find "$dir" -type f | wc -l | tr -d ' ')"
    spec_entries+=("{\"name\":\"$(json_escape "$name")\",\"file_count\":$count}")
  done < <(find "$specs_dir" -mindepth 1 -maxdepth 1 -type d)
fi
spec_dirs_json="[$(IFS=,; echo "${spec_entries[*]}")]"
[ "${#spec_entries[@]}" -eq 0 ] && spec_dirs_json="[]"

# Catch-all: anything under .documentation/ that isn't memory/scripts/specs.
doc_other_entries=()
if [ "$has_documentation_dir" = true ]; then
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    name="$(basename "$entry")"
    case "$name" in
      memory|scripts|specs) continue ;;
    esac
    IFS=$'\t' read -r etype ecount <<< "$(entry_type_and_count "$entry")"
    doc_other_entries+=("{\"name\":\"$(json_escape "$name")\",\"type\":\"$etype\",\"file_count\":$ecount}")
  done < <(find "$docs_dir" -mindepth 1 -maxdepth 1)
fi
doc_other_json="[$(IFS=,; echo "${doc_other_entries[*]}")]"
[ "${#doc_other_entries[@]}" -eq 0 ] && doc_other_json="[]"

# A real DevSpark repo may already have its own root .archive/ convention --
# worth detecting and proposing adoption, not treating as a conflict.
archive_dir="$repo_root/.archive"
has_existing_archive=false
archive_entries=()
if [ -d "$archive_dir" ]; then
  has_existing_archive=true
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    name="$(basename "$entry")"
    IFS=$'\t' read -r etype ecount <<< "$(entry_type_and_count "$entry")"
    archive_entries+=("{\"name\":\"$(json_escape "$name")\",\"type\":\"$etype\",\"file_count\":$ecount}")
  done < <(find "$archive_dir" -mindepth 1 -maxdepth 1)
fi
archive_entries_json="[$(IFS=,; echo "${archive_entries[*]}")]"
[ "${#archive_entries[@]}" -eq 0 ] && archive_entries_json="[]"

# Legacy per-host adapter files -- a class the original mapping table never
# anticipated, since Bold's own adapter system postdates most DevSpark
# installs. Anything found here pre-migration is presumptively legacy (Bold
# hasn't installed its own adapters yet at collection time).
file_names() {
  # $1 = dir -> json array of basenames
  local dir="$1" names=()
  [ -d "$dir" ] || { echo "[]"; return; }
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    names+=("$(basename "$f")")
  done < <(find "$dir" -maxdepth 1 -type f -name '*.md')
  json_array "${names[@]}"
}
legacy_claude_commands_json="$(file_names "$repo_root/.claude/commands")"
legacy_github_agents_json="$(file_names "$repo_root/.github/agents")"
legacy_github_prompts_json="$(file_names "$repo_root/.github/prompts")"
has_agents_registry=false
[ -f "$repo_root/agents-registry.json" ] && has_agents_registry=true

# Multi-app config: named devspark.json per bold-tool-plan.md's own mapping
# table; not every repo has one (single-app is the common case).
has_multi_app_config=false
[ -f "$repo_root/devspark.json" ] && has_multi_app_config=true

# Verification sweep: tracked files (git ls-files respects .gitignore and is
# far faster than a filesystem walk) mentioning "devspark", excluding
# .archive/ (legitimate historical references belong there).
devspark_ref_files=()
if [ -e "$repo_root/.git" ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$f" in
      .archive/*) continue ;;
    esac
    case "$f" in
      *.md|*.json|*.yml|*.yaml|*.txt) ;;
      *) continue ;;
    esac
    full="$repo_root/$f"
    [ -f "$full" ] || continue
    if grep -qil "devspark" "$full" 2>/dev/null; then
      devspark_ref_files+=("$f")
    fi
  done < <(git -C "$repo_root" ls-files 2>/dev/null)
fi
devspark_ref_json="$(json_array "${devspark_ref_files[@]}")"

printf '{"has_devspark_dir":%s,"devspark_dir_file_count":%s,"has_documentation_dir":%s,"has_constitution":%s,"constitution_principle_count":%s,"has_team_scripts_override":%s,"bold_scripts_present":%s,"team_scripts":%s,"spec_dirs":%s,"documentation_other_entries":%s,"has_existing_archive":%s,"existing_archive_entries":%s,"legacy_claude_commands":%s,"legacy_github_agents":%s,"legacy_github_prompts":%s,"has_agents_registry":%s,"has_multi_app_config":%s,"devspark_reference_files":%s}' \
  "$has_devspark_dir" "$devspark_file_count" "$has_documentation_dir" "$has_constitution" \
  "$principle_count" "$has_team_scripts_override" "$bold_scripts_present" "$team_scripts_json" \
  "$spec_dirs_json" "$doc_other_json" "$has_existing_archive" "$archive_entries_json" \
  "$legacy_claude_commands_json" "$legacy_github_agents_json" "$legacy_github_prompts_json" \
  "$has_agents_registry" "$has_multi_app_config" "$devspark_ref_json"
