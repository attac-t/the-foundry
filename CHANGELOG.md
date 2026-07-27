# Changelog

Notable changes to The Foundry. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

Plugins version independently. Each entry names the plugin it belongs to.

---

## Unreleased

### kernel 1.8.0

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

### laravel-ddd 1.3.0 · laravel-playbook 2.4.0 · pest 2.2.0

**Added**

- `"dependencies": ["kernel"]`. Installing a stack plugin now installs the kernel
  automatically, and disabling the kernel while a stack plugin is enabled is
  blocked. This replaces "Requires kernel" in prose.
- `license`, `homepage`, `repository`, and `$schema` in each manifest.

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

- `SECURITY.md` documents what all eight hooks do and states they are read-only
  and offline. CI enforces the offline half.
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
| 2026-02-23 | laravel-playbook: package author's playbook, 30 skills       |
| 2026-02-14 | kernel: three delegation primitives, cognitive friction      |
| 2026-02-06 | kernel: `ground-stack` for contextual stack grounding        |
| 2026-02-04 | pest: suite skills for large test suites                     |
| 2026-01-29 | laravel-ddd: 20 skills extracted from production             |
| 2026-01-24 | kernel: monolith split into a modular cognitive kernel        |
| 2026-01-04 | kernel: branch-aware memory isolation                        |
