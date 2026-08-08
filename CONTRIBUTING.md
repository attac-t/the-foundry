# Contributing

**This line is the gate definition.** Run it before opening a pull request.

```bash
bash bin/mirror.sh && bash bin/frontmatter.sh && bash bin/versions.sh && bash bin/repeats.sh $(git ls-files -co --exclude-standard 'plugins/panel/*.md' 'plugins/pest/*.md' 'plugins/kernel/skills/ground-evidence/*.md' 'plugins/kernel/skills/ground-mechanism/*.md' 'plugins/kernel/skills/craft-plugin-update/*.md') && bash plugins/panel/tests/judges.test.sh && bash plugins/panel/tests/verdicts.test.sh && bash plugins/panel/bin/judges.sh plugins/panel/tests/fixtures/pest-critic.md
```

| Gate | Fails when |
|------|------------|
| `mirror` | this line and `gates.yml` name different commands |
| `frontmatter` | a skill, agent or command is missing the frontmatter that registers it |
| `versions` | `marketplace.json` and a `plugin.json` disagree on a version |
| `repeats` | a sentence appears verbatim in two files — `panel`, `pest`, and three `kernel` skills |
| `judges.test` | `judges.sh` stops rejecting a judge it should reject |
| `verdicts.test` | `verdicts.sh` stops rejecting an approval it should reject |
| `judges` (pest) | `pest:critic` stops being seatable as a judge |

`.claude/panel/` is untracked, so the two gates reading this repo's own charter — `judges.sh` and
`verdicts.sh` with no argument — are not in the chain. They exit 2 without it, and a gate that fails
on a fresh clone is a gate people delete. Run them locally if you use panel here.

The pest gate is deliberately outside panel's own suite: panel installs standalone, so nothing
shipped inside it may assert another plugin is present. That a stack plugin seats an eligible judge
is a fact about this monorepo, and it is checked here.

**What they do not check.** That a plugin still loads, that hook paths resolve, that shell scripts
are valid, that a plugin edit came with a version bump, or anything about `laravel-ddd`,
`laravel-playbook` and most of `kernel` beyond their manifests. Green means those gates passed. It
does not mean the change works.

**They do not run in CI.** GitHub Actions is billing-locked on this account, so no workflow can
obtain a runner and no step in `gates.yml` has ever executed. Treat that file as a copy of the line
above rather than the thing enforcing it, and do not add a step there without adding it here.
Whether `python` resolves on `ubuntu-latest` is unverified, because nothing has tried.

Bump the version in **both** `plugin.json` and `.claude-plugin/marketplace.json` — the manifest is
the one that gets forgotten. Commits use
[Commitizen](https://commitizen-tools.github.io/commitizen/) format.
