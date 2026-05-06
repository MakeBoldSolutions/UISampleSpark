# DevSpark Prompt Templates

This directory contains the **core deliverable** of DevSpark — prompt templates that give AI coding assistants structured commands for specification-driven development.

## Commands (`commands/`)

Each file in `commands/` is a slash-command prompt (e.g., `/devspark.specify`, `/devspark.plan`). When you run `devspark init`, stock prompts are deployed to `.devspark/defaults/commands/`. AI shims then resolve prompts via the 3-tier order: personal override, team override, then stock default.

DevSpark ownership is strictly two-tier:

- `.devspark/` is framework-managed stock content
- `.documentation/` is repository-owned work product and overrides

The collection includes 27 active commands plus 1 deprecated compatibility alias.

| File | Command | Purpose |
|------|---------|---------|
| `specify.md` | `/devspark.specify` | Define requirements and user stories |
| `plan.md` | `/devspark.plan` | Create technical implementation plan |
| `tasks.md` | `/devspark.tasks` | Generate actionable task list |
| `implement.md` | `/devspark.implement` | Execute tasks to build the feature |
| `create-pr.md` | `/devspark.create-pr` | Draft or update a pull request with workflow context |
| `update-pr.md` | `/devspark.update-pr` | Refresh an existing pull request description from the current branch delta |
| `constitution.md` | `/devspark.constitution` | Establish project principles |
| `pr-review.md` | `/devspark.pr-review` | Review PRs against constitution |
| `address-pr-review.md` | `/devspark.address-pr-review` | Address PR review findings with enforced commit isolation |
| `site-audit.md` | `/devspark.site-audit` | Comprehensive codebase audit |
| `commit-audit.md` | `/devspark.commit-audit` | Analyze commit history for workflow, hygiene, and delivery signals |
| `quickfix.md` | `/devspark.quickfix` | Lightweight bug fix workflow |
| `harvest.md` | `/devspark.harvest` | Canonical knowledge-preserving cleanup and archival workflow |
| `release.md` | `/devspark.release` | Archive artifacts and prepare releases |
| `evolve-constitution.md` | `/devspark.evolve-constitution` | Propose constitution amendments |
| `repo-story.md` | `/devspark.repo-story` | Narrative from commit history |
| `critic.md` | `/devspark.critic` | Adversarial risk analysis |
| `clarify.md` | `/devspark.clarify` | Clarify underspecified areas |
| `analyze.md` | `/devspark.analyze` | Cross-artifact consistency check |
| `checklist.md` | `/devspark.checklist` | Quality validation checklists |
| `personalize.md` | `/devspark.personalize` | Create per-user prompt overrides |
| `archive.md` | `/devspark.archive` | Deprecated alias for `/devspark.harvest` |
| `upgrade.md` | `/devspark.upgrade` | Upgrade project to latest templates |
| `discover-constitution.md` | `/devspark.discover-constitution` | Reverse-engineer principles from code |
| `taskstoissues.md` | `/devspark.taskstoissues` | Convert tasks to GitHub issues |
| `add-application.md` | `/devspark.add-application` | Register a new application in the multi-app registry (optional) |
| `list-applications.md` | `/devspark.list-applications` | Display all registered applications (optional) |
| `validate-registry.md` | `/devspark.validate-registry` | Validate registry schema, references, and consistency (optional) |

> **Note**: The three multi-app commands (`add-application`, `list-applications`, `validate-registry`) are only needed for repositories with multiple applications. Single-app repositories can ignore them entirely.

## Helper Templates

| File | Purpose |
|------|---------|
| `spec-template.md` | Template structure for feature specifications |
| `quick-spec-template.md` | Template structure for lightweight quick specifications |
| `plan-template.md` | Template structure for implementation plans |
| `tasks-template.md` | Template structure for task breakdowns |
| `checklist-template.md` | Template structure for quality checklists |
| `spec-validation-contract.md` | Shared validation contract for spec structure and required content |
| `agent-file-template.md` | Template for agent configuration files |
| `vscode-settings.json` | Recommended VS Code settings |
