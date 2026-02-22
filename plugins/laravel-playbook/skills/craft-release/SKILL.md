---
name: craft-release
description: Crafting a release pipeline. One action, full pipeline.
---

# Skill: Craft Release

> "A release should be one click, not a checklist."

## The Standard

1. **GitHub Release triggers everything**: Create a release on GitHub. The changelog updates. Packagist picks up the tag. One action, full pipeline.
1. **Semver strictly followed**: Major for breaking changes. Minor for new features. Patch for fixes. No exceptions, no "we'll bump major just in case."
1. **No `v` prefix on tags**: `7.1.0`, not `v7.1.0`. This is the Packagist convention. Follow it.
1. **CHANGELOG.md auto-updated**: The `update-changelog.yml` workflow uses `stefanzweifel/changelog-updater-action` + `git-auto-commit-action`. Commits directly to `main`. No manual changelog edits.
1. **GitHub auto-generated release notes**: PR-based entries, contributor attribution, compare links. Low maintenance, high value.
1. **Packagist webhook**: Configure once on the GitHub repo. Tag creation triggers package update automatically. No manual publishing.

## The Pipeline

One human action: create the GitHub release. Everything else is automated.

1. Merge PRs to main
1. CI validates (tests, PHPStan, style)
1. Create GitHub release with auto-generated notes
1. `update-changelog.yml` fires -- CHANGELOG.md updated, committed to main
1. Packagist webhook fires -- package version published
1. Dependabot handles downstream updates for consumers

## Version Support Policy

State your support window explicitly in README or SECURITY.md. Three tiers:

| Tier        | Bug Fixes | Security Patches | Example                    |
|-------------|-----------|------------------|----------------------------|
| Active      | Yes       | Yes              | Current major              |
| Maintenance | No        | Yes              | Previous major (12 months) |
| End of Life | No        | No               | Everything else            |

Laravel's window: 18 months bug fixes, 24 months security. For community packages, match your capacity — but be explicit. Undocumented support policy is no support policy.

## The Anti-Patterns

| Don't                              | Do                          | Why                                                |
|------------------------------------|-----------------------------|----------------------------------------------------|
| Manual changelog updates           | Auto-changelog on release   | Humans forget. Automation does not                 |
| `v` prefix on tags                 | No prefix (`7.1.0`)         | Packagist convention. Consistency across ecosystem |
| Manual Packagist publishing        | Packagist webhook           | One-time setup, zero ongoing cost                  |
| Squash without meaningful messages | Meaningful PR titles        | PR titles become changelog entries                 |
| Release branches                   | Release from `main`         | One branch, one pipeline, one truth                |
| Manual release notes               | GitHub auto-generated notes | PR-based, contributor-attributed, link-rich        |

## Real-World Examples

See [examples.md](examples.md).
