---
command: bold.install
subcommand: default
description: Fetch, preview, and sync Bold's payload into this repo (fresh install, upgrade, or already-current), then hand off to bold.plan init.
collector: none
args:
  - name: --source
    description: Manifest source — a published URL, or a local directory (for testing against a Bold checkout).
  - name: --target
    description: Directory the source-tier payload installs into. Defaults to .bold.
---

# bold install

The one Bold prompt meant to be pasted straight into an agent, not invoked as an already-installed command — every other Bold command resolves itself through `.bold/commands/` via three-tier resolution, but on a first run nothing has synced that yet. Read this file in full before acting on it; it fetches data and writes files, and at no point pipes a remote script straight into execution.

No collector: every other command's first step is running a deterministic collector script under `.bold/scripts/`, but that script doesn't exist until this command has already run once. The state-detection steps below are written out explicitly instead, for the same reason collectors exist elsewhere — so state is measured, not judged — just inlined here because there's nowhere else for it to live yet.

## Host notes

This file stays host-neutral on purpose (per `FORMAT.md`: host-specific syntax belongs in adapters, not here) — the same line gets pasted into any agent. Before continuing, fetch `{source}/commands/install/notes/{host}.md` for whichever of `claude-code`, `codex`, or `copilot` you are (you already know which; no detection needed) — if it exists, follow its adjustments; if it 404s or none applies, proceed with the steps below exactly as written. The `Why this shape` section right below is itself host-neutral and always applies regardless.

## Why this shape

A single `curl | bash` / `irm | iex` line executes a remote script sight-unseen, with the user's full privileges, from a domain most people have no way to vouch for. That's indistinguishable from a malware-delivery pattern regardless of what the script actually contains. This command replaces that with three properties: nothing executes before a human has seen it; the actual file-sync logic stays in one deterministic, already-tested script rather than being re-derived as prose; and every write happens through the agent's own tool calls, which a human can watch or interrupt one at a time.

## Detect state

1. Check whether `.bold/version.json` exists.
   - Missing → **Install** (this repo has never synced Bold).
2. Fetch `{source}/latest.json` — a manifest listing file paths, SHA-256 hashes, and sizes; it is data, not code.
   - Compare its `version` field against `.bold/version.json`'s `installed_version`, if step 1 found one.
   - Equal → **Already current.** Report the installed version and stop; don't re-sync without being asked to.
   - Different, or step 1 found nothing → **Install / Upgrade** (same procedure either way — the sync script is idempotent by design: unchanged files are skipped by hash).
3. Note, but do not act on, whether `.devspark/` or `.documentation/` exist at the repo root. That distinction belongs to `bold.plan init`'s Migrate detection (see Hand off below) — installing the Bold payload is identical either way.

## Install / Upgrade

1. Fetch `{source}/install.ps1` (Windows) or `{source}/install.sh` (macOS/Linux) as plain text — a request for a file's contents, nothing executes yet.
2. Summarize what it does in a few sentences (sync loop: skip files whose hash already matches, back up a locally-modified file before overwriting it, delete orphaned files scoped to what Bold owns, scaffold `.bold-user/{git-user-name}/`) — or show the full text if asked. **Wait for explicit go-ahead before continuing.** This is the one ratification point in this command; a script that looks the same as last time still gets shown, not assumed.
3. Write the fetched script, unmodified, to a local temp file.
4. Run it locally: `install.ps1 -Source {source} -Target {target}` (or the bash equivalent). This is the only step that executes anything, and only after step 2's approval.
5. Delete the temp file.

## Hand off

Once `.bold/version.json` reflects the current manifest version, `.bold/commands/plan/init.md` is resolvable through the normal three-tier chain like any other Bold command. Read it and continue directly into it *yourself, in this same conversation, right now* — greenfield/discover/migrate routing already lives there (including the DevSpark detection noted in step 3 above); this command's job ends at "the payload is on disk and current." If the human asked only to install or upgrade, not to proceed further, stop here and report the installed version and paths instead — but say so as plain next-step language ("tell me to continue and I'll pick up `bold.plan init`"), never as a slash command. The `.claude/skills/`, `.agents/skills/`, and `.github/prompts/` shims this run just wrote are not available as invocable commands in *this* session — most hosts index skills at session start, before this install ever ran — so telling a human to type `/bold-plan-init` (or any `/bold-*` command) right now will fail with an unknown-command error even though the file is sitting right there on disk. Reading the next command file directly, the same way this file itself was read, needs no slash command and works immediately; the generated shims only become real slash commands after the human starts a fresh session.

## Definition of Done

Done when `.bold/version.json`'s version matches the fetched manifest, every file the manifest lists is present with a matching hash, and either the human explicitly deferred further setup (reported and stopped) or `bold.plan init` has taken over. Not done if any file was written before the human approved the install/upgrade script in step 2.
