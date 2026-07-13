# Layer Package Format

The schema every package under `source/{starters,stacks,flavors,kits}/` follows. Read this before adding a new starter, stack, flavor, or kit. Twin of `source/commands/FORMAT.md` — that one governs commands, this one governs the layer system behind `bold.plan init`'s greenfield questionnaire (bold-tool-plan.md §11, §12).

## Layer types

| Layer | Directory | Owns | Compatibility |
|---|---|---|---|
| **Starter** | `starters/{name}/` | Spec template, domain questionnaire, worked example, lifecycle interpretation | Declares `compatible_stacks` — the only layer that declares compatibility |
| **Stack** | `stacks/{name}/` | Tech-specific backbone principles, questionnaire branches | Doesn't redeclare compatibility back to starters |
| **Flavor** | `flavors/{name}/` | Targeted principle/convention overlays | Generic — compatible with any starter/stack |
| **Kit** | `kits/{name}.json` | Saved composition + answer defaults — pure metadata, one file, ~10 lines | N/A — a kit *is* a fixed composition |

## Package contents

```
starters/{name}/
├── starter.json        # required
├── questions.json       # optional — omit if the starter asks nothing of its own
├── backbone.md          # optional — pre-answered principle fragment
├── spec-template.md    # required — domain-shaped spec skeleton
├── example/            # required — one complete worked spec→plan→tasks trail
└── system-seed/         # optional — starting system/ taxonomy

stacks/{name}/
├── stack.json           # required
├── questions.json       # optional
└── backbone.md          # optional

flavors/{name}/
├── flavor.json          # required
├── questions.json       # optional
└── backbone.md          # optional

kits/{name}.json         # required, single file
```

`spec-template.md`, `example/`, and `system-seed/` are starter-only — per the layer-types table, stacks and flavors don't own a spec shape, they only contribute principles and questions to whatever starter they're composed with.

## `starter.json` / `stack.json` / `flavor.json`

```json
{
  "name": "api",
  "version": "1.0.0",
  "description": "One line — what this starter/stack/flavor is for.",
  "compatible_stacks": ["dotnet", "node"]
}
```

`compatible_stacks` is required on `starter.json` only; omit it entirely from `stack.json`/`flavor.json`.

## `kits/{name}.json`

```json
{
  "name": "bold-webapp",
  "version": "1.0.0",
  "description": "Fullstack web app: .NET API + React frontend, Tailwind styling.",
  "composition": { "starter": "fullstack", "stacks": ["dotnet", "react"], "flavors": ["tailwind"] },
  "answer_defaults": { "api.style": "REST" }
}
```

A kit doesn't own questions or backbone content of its own — it's a named preset over an existing starter+stacks+flavors composition, plus answer defaults that override whatever those layers' own `questions.json` defaults say. `compose-layers` passes `answer_defaults` through as its own `kit_answer_defaults` field rather than rewriting each question's `default` in place — applying the override is part of *asking*, which belongs to `bold.plan init`, not to a collector that only measures and reports.

## `questions.json`

An array of question objects, one shared shape for every layer. **Every object must be flat — no nested objects anywhere in this file** (arrays of strings are fine). This isn't just a style preference: `compose-layers.sh` parses `questions.json` without a JSON library, using the same single-line regex extraction the rest of Bold's bash tooling already relies on, and that only works because there's never more than one level of `{}` nesting to worry about.

```json
[
  { "id": "api.style", "prompt": "REST or GraphQL?", "type": "select", "options": ["REST", "GraphQL"], "default": "REST", "maps_to": "core.api.style" },
  { "id": "dotnet.target_framework", "prompt": "Target framework?", "type": "text", "default": "net9.0", "when": "dotnet", "maps_to": "layer.dotnet.target_framework" }
]
```

| Field | Required | Notes |
|---|---|---|
| `id` | yes | **Must be unique across the whole composed set for a given run — not just within one layer.** This is the one mechanical conflict `compose-layers` detects. Namespace it (`dotnet.target_framework`, not `target_framework`) so composing with other layers never collides. |
| `prompt` | yes | The question text. |
| `type` | yes | `text`, `select`, `boolean`, or `number`. |
| `options` | when `type: select` | Enumerated choices — a flat array of strings. |
| `default` | yes | Every question has one — Enter-mashing through the whole questionnaire yields a valid project (bold-tool-plan.md §10.2). |
| `when` | no | A layer name (starter/stack/flavor) that must be part of the composition for this question to apply — a flat string, not an object. Omit for unconditional questions. |
| `maps_to` | yes | The genome key (`core.*` or `layer.{layer_id}.*`) this answer populates — see §11's namespace rules. |

## Composition & conflicts

Merge order: **starter → stack(s) → flavor(s) → kit answer-defaults** (bold-tool-plan.md §12.3). `compose-layers` (the collector; see `source/scripts/{bash,powershell}/compose-layers.{sh,ps1}`) concatenates each layer's `questions.json` in that order and its `backbone.md` with provenance tags.

**Conflict scope is deliberately narrow — mechanical only.** The collector flags a conflict when the same `id` appears in more than one layer's `questions.json`; it does not attempt to detect semantic conflicts between backbone fragments (e.g. two layers implying contradictory principles). That's a judgment call for the human/agent during `bold.plan init`'s ratification step, not something a deterministic script should decide. Per Collect/Reason/Ratify, the collector only *reports* — `bold.plan init` is what actually halts and asks when `conflicts` is non-empty, the same pattern as every other halt condition in the neutral prompts.
