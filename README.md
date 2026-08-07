# The Foundry

A curated collection of Claude Code plugins.

---

## Plugins

| Plugin | Purpose |
|--------|---------|
| [kernel](plugins/kernel/README.md) | Cognitive OS. How to think. |
| [panel](plugins/panel/README.md) | Adversarial agent teams. How to verify. |
| [laravel-ddd](plugins/laravel-ddd/README.md) | Laravel DDD patterns. What to build. |
| [laravel-playbook](plugins/laravel-playbook/README.md) | Package author's playbook. How to ship. |
| [pest](plugins/pest/README.md) | Pest v3 syntax. How to test. |

---

## Install

Requires: Claude Code CLI.

```bash
git clone https://github.com/attac-t/the-foundry.git ~/claude-plugins/the-foundry
```

In Claude Code:

```
/plugin marketplace add ~/claude-plugins/the-foundry
/plugin install kernel@the-foundry
```

Add stack plugins as needed:

```
/plugin install laravel-ddd@the-foundry
/plugin install laravel-playbook@the-foundry
/plugin install pest@the-foundry
```

Enable the opinionated voice:

```
/output-style kernel:craftsman
```

Verify the install: `/evaluate`

---

## Contributing

Three gates run on every pull request. Run them before you open one:

```bash
bash bin/frontmatter.sh && bash bin/versions.sh && bash bin/repeats.sh $(git ls-files -co --exclude-standard 'plugins/panel/*.md' 'plugins/pest/*.md') && bash plugins/panel/tests/judges.test.sh && bash plugins/panel/bin/judges.sh
```

| Gate | Fails when |
|------|------------|
| `frontmatter` | a skill, agent or command is missing the frontmatter that registers it |
| `versions` | `marketplace.json` and a `plugin.json` disagree on a version |
| `repeats` | a sentence appears verbatim in two files — scoped to `panel` and `pest` |
| `judges.test` | `judges.sh` stops rejecting a judge it should reject |
| `judges` | this repo's own charter seats an agent that can write what it judges |

**What they do not check:** that a plugin still loads, that hook paths resolve, that shell scripts
are valid, or anything at all about `kernel`, `laravel-ddd` and `laravel-playbook` beyond their
manifests. Green means those gates passed. It does not mean the change works.

**And they do not run in CI.** GitHub Actions is billing-locked on this account — no workflow can
obtain a runner, so every result is one machine, once. Run them yourself and say so.

Bump the version in **both** `plugin.json` and `.claude-plugin/marketplace.json` — the manifest is
the one that gets forgotten. Commits use [Commitizen](https://commitizen-tools.github.io/commitizen/)
format.

---

*Forged with intention.*
