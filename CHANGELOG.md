# Changelog

Notable changes to The Foundry. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Plugins version independently. Each entry names the plugin it belongs to.

---

## Unreleased

### kernel 1.9.0

**Fixed**

- `/polish` shipped with a YAML parse error in its frontmatter, so it loaded with
  no metadata at all. The unquoted `argument-hint: <scope: file, ...>` read as a
  nested mapping. Every `argument-hint` is now quoted.
- `craft-plugin-update` shipped with no frontmatter, which made it invisible to
  Claude. It now has `name` and `description`.
- `craft-handoff` and `craft-observation` were missing from `agents/architect.md`,
  so the architect could not use them despite `/handoff` and `/observe`
  delegating to them.

**Changed**

- `craft-plugin-update` documents the real release path: bump, validate with
  `claude plugin validate --strict`, then `claude plugin tag --push`.

**Added**

- `license`, `homepage`, `repository`, and `$schema` in the manifest.

**Fixed after review**

An independent audit of this branch found defects in the review tooling itself and
in skill content the first pass never opened:

- `validate.sh` matched plugin names with a substring grep over the whole
  manifest, so an unlisted plugin named `php` was reported as listed — three
  entries tag themselves `php`. It was the exact regression the check exists to
  stop. Names are now parsed from JSON and matched exactly, in both directions.
- The orphan-companion check compared against `./` for a file beside `SKILL.md`,
  which matched any skill whose body contained `./` anywhere. Seven skills were
  silently exempt.
- `craft-command` documented `/skills/<name> "$ARGUMENTS"` as *the* pattern, and
  eight commands plus `/agents/architect` in `evaluate.md` used it. No such
  invocation syntax exists; the commands worked only because Claude inferred the
  intent. All nine are now prompts, and the template that mints them says why.
- The `plugins` badge was advertised and unenforced; skill counts derived from
  bare directories rather than `SKILL.md` files; only the first count claim per
  README was checked.

**Added**

- `evolve` and `retrospect`, two scheduled upkeep skills, plus `/evolve` and
  `/retrospect`. `retrospect` runs in your project and mines PR reviews, session
  transcripts, and git history for corrections that should have become memory.
  `evolve` runs in a plugin repo and audits it against a moving ecosystem using
  three adversarial roles.
- [ADR-002](docs/adr/ADR-002-skill-budgets.md): every plugin declares a skill budget
  the build enforces, and all four ship at their cap. A scheduled improvement loop
  would otherwise only ever grow, so an addition must now name what it replaces.

**Accuracy pass over all 118 skills**

Every defect below was verified against the source or the official docs before
changing anything.

- **Memory paths were wrong in five skills.** `$MEMORY_DIR` is a local variable
  inside the hooks and does not exist for Claude. `CLAUDE_MEMORY_DIR` is real but
  names the *base* — `resolve-memory.sh` appends the branch — so
  `$CLAUDE_MEMORY_DIR/spec.md` silently dropped the branch segment. All now use the
  literal `.claude/memory/<branch>/` that `ground-topic` establishes.
- **ADRs had three different homes**: `docs/{domain}/ADR/` in `craft-adr`,
  `docs/*/ADR` in `ground-orientation`, and branch memory in `ground-recitation` —
  which also called them *Permanent* while pointing at a gitignored directory. One
  answer now: draft in branch memory, promote to `docs/adr/` in the PR that needs
  them.
- **`evaluate-plugin` could not fail.** "Run `/blueprint`. Expectation: it should
  load the blueprint" is circular, and "if configured in hooks.json" is an escape
  hatch. Rewritten so every check names its failure signal, including a two-sided
  test for `consider.sh` — firing on everything is as broken as never firing.
- **`ground-action-composition` contradicted itself**: its Standard said "Copy-Paste
  Is OK", its Protocol said extract on the second occurrence. It now defers to
  `decide-abstraction-timing`, which owns the rule of three.
- **`trigger:` is not a frontmatter field** (2 skills). Replaced with the documented
  `when_to_use`, which does exactly that job.
- **`[!CRITICAL]` is not a GitHub alert type** and rendered as a plain blockquote.
- **Two "examples from this codebase" leaks** — these ship to strangers.
- **Emoji register split.** `laravel-ddd` used `❌ Don't / ✅ Do` headers in 21
  skills; the other three plugins and the `craft-skill` templates use neither.
  Brought into line with the template, alignment preserved.

Declined, with reasons: the `decide-*` structure of Decision → Heuristic → Quick
Test is the documented template applied consistently — three views of one decision
for three moments, not repetition. `craft-job` and `craft-queueable-action` were
reported as duplicating a rule verbatim; they share one row, which is the seam
between them.

### laravel-ddd 1.3.0 · laravel-playbook 2.4.0 · pest 2.2.0

**Added**

- `"dependencies": ["kernel"]`. Installing a stack plugin now installs the kernel
  automatically, and disabling the kernel while a stack plugin is enabled is
  blocked. This replaces "Requires kernel" in prose. Requires Claude Code 2.1.143
  or later for the enable/disable half.
- `license`, `homepage`, `repository`, and `$schema` in each manifest.

**Fixed**

- `craft-queueable-action` and `craft-job` documented `Action::onQueue()` as a
  static call, in the skills and in both examples files. Verified against
  `spatie/laravel-queueable-action`: `onQueue()` is an instance method on the
  trait, so the static form throws. The proxy it returns exposes only `execute()`,
  which makes the documented `->delay()` and `->onConnection()` chaining fabricated
  too — connection, delay, and retries are configured on the action.
- `laravel-ddd/polish` recommended an enum `->in()` method that does not exist.
- The pest README led with "Pest v3"; current stable is 4.x. The version pin is
  gone rather than moved, because the skills are not version-specific and a pinned
  major only rots again.

### Repository

**Fixed**

- `marketplace.json` omitted `laravel-playbook` entirely — it was unlistable and
  uninstallable from the marketplace.
- Marketplace entries pinned every plugin at `1.0.0` while the manifests read
  `1.7.0`, `1.2.0`, and `2.1.0`. `plugin.json` wins at install time, so the entry
  versions were dead weight. Removed: `plugin.json` is now the only source.

**Added**

- `LICENSE` (MIT), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, and
  this changelog.
- `.github/validate.sh` — CI runs this exact script, so a green local run means a
  green build. Catches an unlisted plugin, a duplicated version, a
  skill whose name disagrees with its directory, a broken or orphaned companion
  file, an unregistered skill, a hook that lost its executable bit or gained a
  network call, and a stale skill count in any README.
- CI on every push and pull request, plus Dependabot for the actions it uses.
- Issue templates for bug reports and skill proposals.
- [ADR-001](docs/adr/ADR-001-plugin-version-single-source.md) on why the version
  lives in exactly one file.

**Changed**

- `SECURITY.md` documents all ten shell files, names every program they invoke, and
  flags that `verify.sh` can block a stop rather than merely print. CI guards the
  offline claim as a regression check, not as a sandbox — the document says so.
- `plugins/kernel/README.md` dropped from 294 lines to 198; the stack-plugin
  authoring guide moved to `plugins/kernel/docs/authoring-stack-plugins.md`.
- Every README's install block is one command now that `dependencies` pulls in the
  kernel. `Run /skills <plugin>` is gone from two READMEs — no such command
  exists. They link to the `skills/` directory instead.

---

## Earlier

This changelog starts here. For history before it, the commit log is accurate and
scoped:

```bash
git log --oneline --no-merges
```

Highlights:

| Date       | Change                                                       |
|------------|--------------------------------------------------------------|
| 2026-03-08 | kernel: seven-pass polish protocol                           |
| 2026-02-23 | laravel-playbook: package author's playbook, 29 skills       |
| 2026-02-14 | kernel: three delegation primitives, cognitive friction      |
| 2026-02-06 | kernel: `ground-stack` for contextual stack grounding        |
| 2026-02-04 | pest: suite skills for large test suites                     |
| 2026-01-29 | laravel-ddd: 20 skills extracted from production             |
| 2026-01-24 | kernel: monolith split into a modular cognitive kernel        |
| 2026-01-04 | kernel: branch-aware memory isolation                        |
