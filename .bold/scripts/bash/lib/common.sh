#!/usr/bin/env bash
# Shared helpers for bold's bash collector scripts.

bold_user_slug() {
  # Filesystem-safe slug identifying the current contributor for
  # .bold-user/{slug}/ (bold-tool-plan.md §17 #4 — committed, per-user
  # tier). Falls back from git user.name to the email's local part, then
  # to "shared" if neither is configured. $1 (optional) scopes the git
  # config lookup to a specific repo root instead of the caller's cwd --
  # required, not cosmetic: a script invoked with --root pointing elsewhere
  # must not silently read the invoking shell's own git identity instead.
  local root="${1:-}" name email slug
  if [ -n "$root" ]; then
    name="$(git -C "$root" config user.name 2>/dev/null || true)"
  else
    name="$(git config user.name 2>/dev/null || true)"
  fi
  if [ -z "$name" ]; then
    if [ -n "$root" ]; then
      email="$(git -C "$root" config user.email 2>/dev/null || true)"
    else
      email="$(git config user.email 2>/dev/null || true)"
    fi
    name="${email%%@*}"
  fi
  [ -n "$name" ] || name="shared"
  slug="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')"
  [ -n "$slug" ] || slug="shared"
  printf '%s' "$slug"
}

json_escape() {
  # Escapes backslash/quote first (order matters), then newlines, CR, and
  # tabs -- found via compose-layers.sh, the first caller to ever pass
  # multi-line content (backbone.md fragments) through this helper.
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g; s/\r/\\r/g; s/\t/\\t/g'
}

json_array() {
  local parts=()
  for item in "$@"; do
    parts+=("\"$(json_escape "$item")\"")
  done
  if [ "${#parts[@]}" -eq 0 ]; then
    echo "[]"
  else
    (IFS=,; echo "[${parts[*]}]")
  fi
}

# Emits a JSON array of repo-relative paths under bold-docs/system/
collect_system_docs() {
  local repo_root="$1"
  local docs_dir="$2"
  local files=()
  if [ -d "$docs_dir/system" ]; then
    mapfile -t files < <(find "$docs_dir/system" -type f ! -name '.gitkeep' | sed "s|^$repo_root/||" | sort)
  fi
  json_array "${files[@]}"
}

# Emits a JSON array of {principle,reason,ratified_by,date}, one per
# `- Waiver: ...` line in the given spec file. See source/commands/WAIVERS.md
# for the line format.
collect_waivers_for_spec() {
  local spec="$1"
  local entries=()
  local line principle reason ratified_by date
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    principle="$(printf '%s' "$line" | sed -E 's/.*principle=([0-9]+).*/\1/')"
    reason="$(printf '%s' "$line" | sed -E 's/.*reason="([^"]*)".*/\1/')"
    ratified_by="$(printf '%s' "$line" | sed -E 's/.*ratified_by="([^"]*)".*/\1/')"
    date="$(printf '%s' "$line" | sed -E 's/.*date=([0-9-]+).*/\1/')"
    entries+=("{\"principle\":${principle:-null},\"reason\":\"$(json_escape "$reason")\",\"ratified_by\":\"$(json_escape "$ratified_by")\",\"date\":\"$(json_escape "$date")\"}")
  done < <(grep -oE '^- Waiver: .*' "$spec" 2>/dev/null; printf '\n')
  if [ "${#entries[@]}" -eq 0 ]; then
    echo "[]"
  else
    (IFS=,; echo "[${entries[*]}]")
  fi
}

# Emits a JSON array of {id,status,tier,waivers}, one per
# bold-docs/features/*/spec.md
collect_active_features() {
  local docs_dir="$1"
  local entries=()
  if [ -d "$docs_dir/features" ]; then
    for dir in "$docs_dir/features"/*/; do
      [ -d "$dir" ] || continue
      local id spec status tier waivers
      id="$(basename "$dir")"
      spec="$dir/spec.md"
      [ -f "$spec" ] || continue
      status="$(sed -n 's/^\*\*Status\*\*: //p' "$spec" | head -1)"
      tier="$(sed -n 's/^\*\*Tier\*\*: //p' "$spec" | head -1)"
      waivers="$(collect_waivers_for_spec "$spec")"
      entries+=("{\"id\":\"$(json_escape "$id")\",\"status\":\"$(json_escape "${status:-unknown}")\",\"tier\":\"$(json_escape "${tier:-unknown}")\",\"waivers\":$waivers}")
    done
  fi
  if [ "${#entries[@]}" -eq 0 ]; then
    echo "[]"
  else
    (IFS=,; echo "[${entries[*]}]")
  fi
}

# Emits a JSON array of {doc,reference}, one per backtick-quoted, path-shaped
# reference in a bold-docs/system/ doc that doesn't resolve to a real file.
# Scoped to system/ only (§13 ambient staleness detection) -- feature specs
# are expected to reference code that doesn't exist yet.
collect_stale_references() {
  local repo_root="$1"
  local docs_dir="$2"
  local system_dir="$docs_dir/system"
  local entries=()
  [ -d "$system_dir" ] || { echo "[]"; return; }
  local doc rel_doc ref
  while IFS= read -r doc; do
    [ -n "$doc" ] || continue
    rel_doc="${doc#"$repo_root"/}"
    while IFS= read -r ref; do
      [ -n "$ref" ] || continue
      case "$ref" in
        http://*|https://*|*\**) continue ;;
      esac
      if [ ! -e "$repo_root/$ref" ]; then
        entries+=("{\"doc\":\"$(json_escape "$rel_doc")\",\"reference\":\"$(json_escape "$ref")\"}")
      fi
    done < <(grep -oE '`[A-Za-z0-9_.-]+(/[A-Za-z0-9_.-]+)+`' "$doc" 2>/dev/null | tr -d '`' | sort -u; printf '\n')
  done < <(find "$system_dir" -type f ! -name '.gitkeep' 2>/dev/null | sort; printf '\n')
  if [ "${#entries[@]}" -eq 0 ]; then
    echo "[]"
  else
    (IFS=,; echo "[${entries[*]}]")
  fi
}

# Emits a JSON array of {n,status}, one per numbered principle in backbone.md
collect_backbone_principles() {
  local docs_dir="$1"
  local backbone_file="$docs_dir/backbone.md"
  local entries=()
  local n=0
  if [ -f "$backbone_file" ]; then
    while IFS= read -r status; do
      [ -n "$status" ] || continue
      n=$((n+1))
      entries+=("{\"n\":$n,\"status\":\"$(json_escape "$status")\"}")
    done < <(sed -n 's/^[[:space:]]*\*\*Status\*\*: //p' "$backbone_file"; printf '\n')
  fi
  if [ "${#entries[@]}" -eq 0 ]; then
    echo "[]"
  else
    (IFS=,; echo "[${entries[*]}]")
  fi
}
