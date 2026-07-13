#!/usr/bin/env bash
# Collector for bold.plan init's greenfield questionnaire. Given a starter
# (+ optional stacks/flavors) or a kit, resolves the full layer set, merges
# each layer's questions.json in composition order (starter -> stacks ->
# flavors), and flags any question `id` that appears in more than one layer
# as a conflict. A kit's answer_defaults pass through unmodified as their own
# field -- applying the override is part of *asking*, which belongs to
# bold.plan init, not to this collector, which only measures and reports.
#
# Parses questions.json/kit.json with sed/grep tuned to the exact flat shape
# source/starters/FORMAT.md requires (at most one level of {} nesting) --
# not a general JSON parser, same no-new-dependency discipline as every
# other bash collector in this repo.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./lib/common.sh
source "$script_dir/lib/common.sh"

layers_root=""
kit=""
starter=""
stacks_csv=""
flavors_csv=""

while [ $# -gt 0 ]; do
  case "$1" in
    --layers-root) layers_root="$2"; shift 2 ;;
    --kit) kit="$2"; shift 2 ;;
    --starter) starter="$2"; shift 2 ;;
    --stacks) stacks_csv="$2"; shift 2 ;;
    --flavors) flavors_csv="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done
[ -n "$layers_root" ] || layers_root="$repo_root/source"

# Field extractors, tuned to a single-line (newline-stripped) flat JSON
# object/array -- no general JSON parsing, per the format's own no-nesting
# rule (source/starters/FORMAT.md).
strip_nl() { tr -d '\n' < "$1"; }
extract_string() { printf '%s' "$1" | sed -n -E "s/.*\"$2\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/p"; }
extract_bracket() { printf '%s' "$1" | sed -n -E "s/.*\"$2\"[[:space:]]*:[[:space:]]*\[([^]]*)\].*/\1/p"; }
extract_brace() { printf '%s' "$1" | sed -n -E "s/.*\"$2\"[[:space:]]*:[[:space:]]*\{([^{}]*)\}.*/\1/p"; }
# Turns `"a","b"` into a bash array via json_array's inverse -- strip quotes, split on comma.
csv_from_bracket() {
  [ -n "$1" ] || return 0
  printf '%s' "$1" | tr ',' '\n' | sed -E 's/^[[:space:]]*"(.*)"[[:space:]]*$/\1/'
}

kit_answer_defaults_json="{}"

if [ -n "$kit" ]; then
  kit_path="$layers_root/kits/$kit.json"
  [ -f "$kit_path" ] || { echo "Kit not found: $kit_path" >&2; exit 1; }
  kit_content="$(strip_nl "$kit_path")"
  starter="$(extract_string "$kit_content" starter)"
  stacks_csv="$(csv_from_bracket "$(extract_bracket "$kit_content" stacks)" | paste -sd, -)"
  flavors_csv="$(csv_from_bracket "$(extract_bracket "$kit_content" flavors)" | paste -sd, -)"
  answer_defaults_body="$(extract_brace "$kit_content" answer_defaults)"
  kit_answer_defaults_json="{${answer_defaults_body:-}}"
fi

[ -n "$starter" ] || { echo "Either --kit or --starter is required" >&2; exit 1; }

stacks=()
flavors=()
[ -n "$stacks_csv" ] && IFS=',' read -ra stacks <<< "$stacks_csv"
[ -n "$flavors_csv" ] && IFS=',' read -ra flavors <<< "$flavors_csv"

# Build ordered layer refs as type:name pairs.
layer_refs=("starter:$starter")
for s in "${stacks[@]}"; do [ -n "$s" ] && layer_refs+=("stack:$s"); done
for f in "${flavors[@]}"; do [ -n "$f" ] && layer_refs+=("flavor:$f"); done

question_objs=()   # each entry: the full {..."source":"type:name"} JSON object string
backbone_frags=()

for ref in "${layer_refs[@]}"; do
  type="${ref%%:*}"
  name="${ref#*:}"
  dir="$layers_root/${type}s/$name"
  source_tag="$type:$name"

  questions_path="$dir/questions.json"
  if [ -f "$questions_path" ]; then
    flat="$(strip_nl "$questions_path")"
    while IFS= read -r obj; do
      [ -n "$obj" ] || continue
      # Insert ,"source":"..." just before the object's closing brace.
      tagged="${obj%\}},\"source\":\"$(json_escape "$source_tag")\"}"
      question_objs+=("$tagged")
    done < <(printf '%s' "$flat" | grep -oE '\{[^{}]*\}')
  fi

  backbone_path="$dir/backbone.md"
  if [ -f "$backbone_path" ]; then
    content="$(cat "$backbone_path")"
    backbone_frags+=("{\"source\":\"$(json_escape "$source_tag")\",\"content\":\"$(json_escape "$content")\"}")
  fi
done

composed_questions_json="[$(IFS=,; echo "${question_objs[*]}")]"
[ "${#question_objs[@]}" -eq 0 ] && composed_questions_json="[]"
backbone_fragments_json="[$(IFS=,; echo "${backbone_frags[*]}")]"
[ "${#backbone_frags[@]}" -eq 0 ] && backbone_fragments_json="[]"

# Mechanical conflict detection: any id appearing in more than one layer.
declare -A id_sources=()
declare -a id_order=()
for obj in "${question_objs[@]}"; do
  [ -n "$obj" ] || continue
  id="$(printf '%s' "$obj" | sed -n -E 's/.*"id"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p')"
  src="$(printf '%s' "$obj" | sed -n -E 's/.*"source"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p')"
  [ -n "$id" ] || continue
  if [ -z "${id_sources[$id]+x}" ]; then
    id_order+=("$id")
    id_sources[$id]="$src"
  else
    id_sources[$id]="${id_sources[$id]},$src"
  fi
done

conflict_entries=()
for id in "${id_order[@]}"; do
  IFS=',' read -ra srcs <<< "${id_sources[$id]}"
  if [ "${#srcs[@]}" -gt 1 ]; then
    conflict_entries+=("{\"id\":\"$(json_escape "$id")\",\"sources\":$(json_array "${srcs[@]}")}")
  fi
done
conflicts_json="[$(IFS=,; echo "${conflict_entries[*]}")]"
[ "${#conflict_entries[@]}" -eq 0 ] && conflicts_json="[]"

stacks_json="$(json_array "${stacks[@]}")"
flavors_json="$(json_array "${flavors[@]}")"
kit_field="null"
[ -n "$kit" ] && kit_field="\"$(json_escape "$kit")\""

printf '{"composition":{"kit":%s,"starter":"%s","stacks":%s,"flavors":%s},"composed_questions":%s,"conflicts":%s,"backbone_fragments":%s,"kit_answer_defaults":%s}' \
  "$kit_field" "$(json_escape "$starter")" "$stacks_json" "$flavors_json" \
  "$composed_questions_json" "$conflicts_json" "$backbone_fragments_json" "$kit_answer_defaults_json"
