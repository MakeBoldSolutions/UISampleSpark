# Codex — install notes

No adjustment needed to the base steps in `install/default.md`. Use whichever of your own tools reads a URL as plain text and writes a local file — no Codex-specific fetch directive is assumed here, because none is confirmed to exist across Codex clients; plain natural-language "fetch and read" instructions work.

One path detail: skill files this manifest installs after sync live under `.agents/skills/{slug}/SKILL.md`, mirroring Claude Code's `SKILL.md` format.
