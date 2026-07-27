# The Foundry

@README.md

---

## Rules

### Version Bump — Every Time

After modifying ANY file inside a plugin, bump its version via `craft-plugin-update`.

Version lives in `plugin.json` only. Never in `marketplace.json` — see
[ADR-001](docs/adr/ADR-001-plugin-version-single-source.md).

### Validate Before Claiming Done

```bash
./.github/validate.sh
```

Green, or it isn't done. CI runs this exact script.

### New Kernel Skill

Register it in `skills:` in `plugins/kernel/agents/architect.md`. Sub-agents do
not inherit skills. Unregistered skills do not exist.

### New Plugin

Add an entry to `.claude-plugin/marketplace.json` — `name` and `source`, no
`version`. A stack plugin also declares `"dependencies": ["kernel"]`.

### Skill Counts Are Enforced

READMEs advertise skill counts and a badge advertises the total. Add or remove a
skill and those numbers must move with it. `validate.sh` fails otherwise.

### Commits

[Commitizen](https://commitizen-tools.github.io/commitizen/) format: `type(scope): description`

### Pull Requests

Follow `.github/PULL_REQUEST_TEMPLATE.md`.

### Stack Plugins

Before modifying a stack plugin, read its README. After modifying it, check if the README needs updating.

### Voice

Craftsman. Always.
