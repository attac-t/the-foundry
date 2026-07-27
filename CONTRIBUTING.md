# Contributing

Thanks for being here. This guide gets you from clone to merged PR.

---

## Setup

```bash
git clone https://github.com/attac-t/the-foundry.git ~/claude-plugins/the-foundry
```

Point Claude Code at your clone:

```
/plugin marketplace add ~/claude-plugins/the-foundry
```

You need the `claude` CLI to validate. Nothing else — no build, no dependencies.

---

## Layout

```
plugins/<plugin>/
├── .claude-plugin/plugin.json   Manifest. Owns the version.
├── skills/<skill>/SKILL.md      One concept per file.
├── commands/<name>.md           Slash commands (kernel only).
├── hooks/                       Shell reflexes (kernel only).
├── agents/                      Sub-agent personas (kernel only).
└── README.md                    What this plugin is for.
```

Components live at the plugin root. Only `plugin.json` goes in `.claude-plugin/`.

---

## Skills

A skill is an atomic unit of judgment. Three kinds, and the prefix tells you which:

| Prefix    | Answers            | Example              |
|-----------|--------------------|----------------------|
| `ground-` | How should I think? | `ground-elegance`    |
| `craft-`  | How do I build X?   | `craft-action`       |
| `decide-` | X or Y?             | `decide-dto-vs-array`|

Run `/craft-skill` for the templates. The bar:

- **Atomic.** One concept. Two concepts means two skills.
- **Brief.** Three quarters of existing skills are under 50 lines. Long examples
  go in `examples.md`.
- **Expert.** Write how a senior engineer thinks, not a checklist they follow.

Deep code goes in `examples.md` next to `SKILL.md`, never inline.

> [!IMPORTANT]
> A new kernel skill must be added to `skills:` in `agents/architect.md`.
> Sub-agents don't inherit skills. Unregistered skills do not exist.

---

## Workflow

1. **Branch.** `feat/<thing>` or `fix/<thing>`. Never commit to `main`.
2. **Change** one thing. A PR that touches three plugins is three PRs.
3. **Bump** the `version` in that plugin's `plugin.json`. Every change, every time.
   See `/craft-plugin-update` for which digit.
4. **Validate.** Green before you push:

   ```bash
   ./.github/validate.sh
   ```

5. **Commit** in [Commitizen](https://commitizen-tools.github.io/commitizen/) format:

   ```
   feat(kernel): add ground-observability skill
   ```

   Types: `feat`, `fix`, `docs`, `refactor`, `chore`. Scope is the plugin name.
6. **Open a PR** using the template. CI runs the same script you just ran.

---

## Versioning

Each plugin versions independently. `plugin.json` is the only place a version
lives — never duplicate it into `marketplace.json`, because `plugin.json` wins at
install time and the copy just rots.

| Change            | Bump  |
|-------------------|-------|
| Typo, docs        | Patch |
| Skill refinement  | Patch |
| New skill         | Minor |
| Renamed skill     | Major |
| Removed skill     | Major |

Renames and removals are breaking. Someone has that name in muscle memory.

---

## Voice

Craftsman. Direct, opinionated, no hedging.

| Instead of                              | Write        |
|-----------------------------------------|--------------|
| "You might want to consider refactoring"| "Refactor."  |
| "It is generally recommended that..."   | "Do X."      |
| "This could potentially be improved"    | "This is slow." |

Tables for cataloging. Trees for structure. Code over prose. Cut every word that
earns nothing.

---

## What Gets Merged

Skills that encode judgment you'd defend in a code review. Bug fixes. Sharper
wording.

What doesn't: syntax reference you'd get from the framework docs, skills that
restate a `ground-*` philosophy in different words, or hedged advice. If a skill
can't take a position, it isn't a skill.

Not sure it fits? Open an issue first. Cheaper than writing it twice.

---

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

---

*Forged with intention.*
