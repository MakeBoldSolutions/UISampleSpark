# Neutral Prompt Format

The schema every file under `source/commands/` follows. Read this before writing a new command or subcommand.

## Layout

One file per subcommand: `source/commands/{plan,build,ship}/{subcommand}.md`. The bare command (`bold.plan` with no subcommand) lives at `{command}/default.md`. See `bold-docs/features/0001-neutral-prompt-format/spec.md` for why (whole-file override replacement per plan §5.3 means subcommand-level granularity, not one file per top-level command).

`source/commands/install/default.md` (`bold.install`) is a deliberate fourth entry, not a widening of the three frozen methodology verbs (§18 risk table) — it's pre-methodology bootstrap: the payload-sync step that has to exist before `plan`/`build`/`ship` are on disk to run at all. It reuses the same `bold.<verb>` frontmatter shape purely so the existing slug/adapter-generation machinery (`generate-adapters.{sh,ps1}`, `generate-site.{sh,ps1}`) needs no bespoke handling — treat the `command: bold.install` value as tooling convenience, not a claim that installation is a fourth thing Bold's methodology does.

## File shape

```markdown
---
command: bold.plan
subcommand: critic
description: One line — what this subcommand does.
collector: collect-triage-context   # or: none, with a comment explaining why
args:
  - name: --strict
    description: What the flag changes.
    values: [optional, enum, list]  # omit if free-form
---

# bold.plan critic

Agent-neutral markdown body.
```

### Frontmatter fields

| Field | Required | Notes |
|---|---|---|
| `command` | yes | `bold.plan` / `bold.build` / `bold.ship` |
| `subcommand` | yes | `default` for the bare command |
| `description` | yes | One line; this is what an adapter generator turns into the host's command description |
| `collector` | yes | The collector script's base name (no extension — both `source/scripts/bash/{name}.sh` and `source/scripts/powershell/{name}.ps1` must exist), or the literal `none` if the subcommand's only input is a file already on disk. Never omit the field — an absent collector should be a stated decision, not a gap |
| `args` | yes (may be empty `[]`) | Flags the subcommand accepts, each with a one-line `description` |

### Body

- Markdown, no host-specific syntax — no Claude Code frontmatter keys, no Copilot directives, no Cursor rule syntax. Anything host-specific belongs in `adapters/`, not here.
- Open with a short statement of purpose, then boundaries (success criteria, halt conditions) — not a scripted step-by-step procedure the model would handle sensibly on its own (backbone principle: guardrails bound the space, never script the path).
- **A `## Definition of Done` section is required.** Plan §1 is explicit: "no prompt without success criteria either... Prompts are components with contracts, not text that gets eyeballed and shipped." One to three sentences stating what "done" concretely means for this subcommand — specific enough that a different agent run against the same input would recognize the same stopping point. Not a restatement of the body's steps; a test you could check the output against afterward.
- The Product Owner TL;DR requirement (plan §8) lives in the body wherever this subcommand instructs the agent to produce a durable artifact — it's part of what the methodology produces, not adapter-injected boilerplate.
- Reference collector output fields by name (e.g. `active_features`, `backbone_principles`) rather than re-describing how to gather them — the collector already did that.

## Ratification contract

Any command body that asks a human to ratify substantial produced content (a migration report, a discovery playback, a harvest classification, a planning artifact) binds three clauses. Each traces to a real observed failure — all three failed at once during the second crucible migration (BootstrapSpark, 2026-07-09; see `bold-docs/patches.md`), where "ratified" turned out to mean "nodded past a summary of a document the human had never seen, saved where nobody would find it, backed by a pass/fail check that hid two wrong documents."

1. **Seen means quoted.** The content being ratified appears in the agent's own visible response. A `Read`/`Write` tool call renders as a collapsed action in most hosts — "I read/wrote the file" and "the human saw the content" are different events, even when the human explicitly asked to see it.
2. **Working documents live in the target repo.** A file saved for ratification sits inside the repo the human already has open — gitignored, disposable — never an OS-level temp path. A document nobody can find can only be nodded past, not ratified.
3. **Verification is per-item.** An acceptance check backing a ratification accounts for each hit individually with a one-line justification; a bare pass/fail count ("N hits, all legitimate") is not accountable to anything.

`plan/init.md`'s Migrate section is the worked example — the clauses were first written there, in full, where the failures occurred. Every other ratify step binds the applicable clauses in **one sentence referencing this section**, never a restatement (restatement is exactly the prompt-density accretion the minimal-intervention principle exists to prevent). Commands whose ratified content is inherently conversational — clarification questions, gate acknowledgements, review findings — have no file-plus-summary path to fail through and bind nothing.

## Collector convention

Collector scripts emit single-line JSON to stdout, one pair per platform: `source/scripts/bash/{name}.sh` and `source/scripts/powershell/{name}.ps1`, verified to produce equivalent output. Shared parsing logic (feature inventory, backbone principle status, system-doc inventory) lives in `source/scripts/bash/lib/common.sh` and `source/scripts/powershell/lib/Common.ps1` — reach for those before duplicating a scan across a third script.

## Worked examples

All 14 files under `source/commands/{plan,build,ship}/` follow this schema and are the reference set — `plan/default.md` (the triage flow) is the most heavily annotated. `install/default.md` also follows it but is the one legitimate exception to the collector rule above — see its own file for why.
