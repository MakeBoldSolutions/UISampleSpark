# Claude Code — install notes

No adjustment needed to the base steps in `install/default.md`. Claude Code's own `Read`/`WebFetch` tools and its per-call permission system already give the fetch-then-preview-then-write flow those steps describe; there's nothing host-specific to substitute.

One path detail: skill files this manifest installs after sync live under `.claude/skills/{slug}/SKILL.md`, one directory per command.
