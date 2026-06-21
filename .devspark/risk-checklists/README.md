# Risk Checklists

Loaded by `/devspark.critic` (see [`templates/commands/critic.md`](../commands/critic.md) §7) to apply stack- and archetype-specific failure-mode lenses on top of the universal Risk Category Registry.

## File naming

- **Stack** files: `{language}-{framework}.md` — e.g., `python-fastapi.md`, `node-express.md`, `go-gin.md`, `java-spring.md`, `dotnet-aspnet.md`.
- **Archetype** files: `{archetype}.md` — e.g., `web-service.md`, `library.md`, `cli.md`, `data-pipeline.md`, `ml-training.md`, `infrastructure.md`, `mobile-app.md`, `embedded.md`, `browser-extension.md`.

Critic loads all files whose name matches either the detected stack or the detected archetype, then unions the items. If none match, it falls back to the universal failure-mode lens defined in `critic.md`.

## Entry format

Each bullet pairs a **capability** with a **named tool example set** so the model can translate the risk to other ecosystems:

```markdown
- [ ] **{Capability needed}** — e.g., {Tool A in stack X}, {Tool B in stack Y}, {Tool C in stack Z}
```

Keep entries short, single-line, action-shaped. Map each entry implicitly to a registry category in `critic.md` §6 (`auth_authz`, `scale_bottlenecks`, etc.).

## Curation rules

- **No tool-only entries.** Every line must lead with the capability so it generalizes.
- **No duplicates of registry cue sheets.** Only add items that are stack/archetype-specific.
- **Drop dead entries.** If a check no longer applies (e.g., framework feature became the default), remove it.
- **Prefer high-incident risks.** These lists are seeded from production-incident patterns; resist adding theoretical concerns.

Teams override or extend these files by copying the relevant file into `.documentation/risk-checklists/` in their consuming repo (override path takes priority during load).
