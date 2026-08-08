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

**This line is the gate definition.** Run it before you open a pull request — see below for why that
is not a formality. `.github/workflows/gates.yml` mirrors it and has never run.

```bash
bash bin/gates-agree.sh && bash bin/frontmatter.sh && bash bin/versions.sh && bash bin/repeats.sh $(git ls-files -co --exclude-standard 'plugins/panel/*.md' 'plugins/pest/*.md' 'plugins/kernel/skills/ground-evidence/*.md' 'plugins/kernel/skills/ground-mechanism/*.md' 'plugins/kernel/skills/craft-plugin-update/*.md') && bash plugins/panel/tests/judges.test.sh && bash plugins/panel/tests/verdicts.test.sh && bash plugins/panel/bin/judges.sh plugins/panel/tests/fixtures/pest-critic.md
```

| Gate | Fails when |
|------|------------|
| `gates-agree` | this line and `gates.yml` name different commands |
| `frontmatter` | a skill, agent or command is missing the frontmatter that registers it |
| `versions` | `marketplace.json` and a `plugin.json` disagree on a version |
| `repeats` | a sentence appears verbatim in two files — `panel`, `pest`, and three `kernel` skills |
| `judges.test` | `judges.sh` stops rejecting a judge it should reject |
| `verdicts.test` | `verdicts.sh` stops rejecting an approval it should reject |
| `judges` (pest) | `pest:critic` stops being seatable as a judge |

**`.claude/panel/` is not tracked**, so the two gates that read this repo's own charter — `judges.sh`
and `verdicts.sh` with no argument — are not in the chain. They exit 2 without it, and a gate that
fails on a fresh clone is a gate people delete. Run them locally if you use panel here; the suites
above cover the scripts themselves against fixtures.

**The last one is deliberately not in panel's own suite.** Panel installs standalone, so nothing
shipped inside it may assert that another plugin is present. That a stack plugin seats an eligible
judge is a fact about *this monorepo*, and it is checked here.

**What they do not check:** that a plugin still loads, that hook paths resolve, that shell scripts
are valid, that a plugin edit was accompanied by a version bump, or anything about `laravel-ddd`,
`laravel-playbook` and most of `kernel` beyond their manifests — the prose gate reaches three kernel
skills and no further. Green means those gates passed. It does not mean the change works.

**And they do not run in CI.** GitHub Actions is billing-locked on this account — no workflow can
obtain a runner, so every result is one machine, once. Run them yourself and say so.

That is true of **every** step in `gates.yml`, not some backlog of recent ones — the file has never
run at all. Counting them here was itself a small instance of the problem: the number was written
three times across two files and three charters, and was wrong in all three by the time anyone
looked. Treat `gates.yml` as a copy of the line above rather than as the thing that enforces it,
and do not add a step there without adding it here. Whether `python` even resolves on
`ubuntu-latest` is unverified, because nothing has ever tried.

Bump the version in **both** `plugin.json` and `.claude-plugin/marketplace.json` — the manifest is
the one that gets forgotten. Commits use [Commitizen](https://commitizen-tools.github.io/commitizen/)
format.

---

*Forged with intention.*
