# ADR-001: `plugin.json` is the only source of a plugin version

**Status**: Accepted
**Date**: 2026-07-27

## Context

A version can be declared in two places: a plugin's `.claude-plugin/plugin.json`
and its entry in `.claude-plugin/marketplace.json`.

Both were populated, and they disagreed. The marketplace pinned every plugin at
`1.0.0` while the manifests read `1.7.0`, `1.2.0`, and `2.1.0`. Nobody noticed,
because nothing visibly broke.

Nothing broke because `plugin.json` wins at install time. The marketplace value
was being silently discarded — it looked authoritative and did nothing.

`marketplace.json` had also drifted structurally: `laravel-playbook` was missing
from it entirely, so the plugin could not be installed at all.

## Decision

Version lives in `plugin.json`. It does not appear in `marketplace.json`.

Marketplace entries carry only what is genuinely marketplace-scoped: `name`,
`source`, `description`, `category`, `tags`.

`.github/validate.sh` fails the build if `marketplace.json` regains a `version`
key, or if any `plugins/*` directory is missing an entry.

**Rejected: keep both in sync.** Two sources of truth with a manual sync step is
the setup that produced the drift. The official validator only warns on a
mismatch, and a warning nobody reads is not a control.

**Rejected: omit `version` everywhere** and let Claude Code fall back to the git
commit SHA. Every commit would then be a new version for every user. Right for an
internal plugin under active development; wrong for a published one, where a
release should be a deliberate act.

## Consequences

+ One place to change, so drift is structurally impossible rather than merely
  discouraged.
+ Releases stay deliberate. Users update when a version is bumped, not on every
  push to `main`.
+ CI catches both failure modes that actually occurred here.
- Contributors must remember the bump. Mitigated by `craft-plugin-update`, a
  `CLAUDE.md` rule, and the table in `CONTRIBUTING.md`.
- Version constraints between plugins (`{ "name": "kernel", "version": "^1.8" }`)
  need git tags in `<plugin>--v<version>` form. We use bare-string dependencies
  today, so no tags are required yet. Adding a constraint later means adopting
  `claude plugin tag --push` as part of the release.
