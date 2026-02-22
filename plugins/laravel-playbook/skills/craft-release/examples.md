# Release: Examples

Patterns from production packages.

---

## The Pattern

### CHANGELOG Format

**Why?** Descending chronological. Each entry links to the PR. New contributors get attribution.

```markdown
# Changelog

## 3.2.0 - 2026-02-15

### What's Changed

* Add support for custom filters by @author in https://github.com/org/package/pull/42
* Fix cache invalidation on model update by @author in https://github.com/org/package/pull/43

### New Contributors

* @contributor made their first contribution in https://github.com/org/package/pull/43

**Full Changelog**: https://github.com/org/package/compare/3.1.0...3.2.0
```

---

## Common Scenarios

### The Update Changelog Workflow

**Why?** One action, full pipeline. No manual changelog edits.

```yaml
# .github/workflows/update-changelog.yml
name: Update Changelog

on:
  release:
    types: [released]

jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: main

      - uses: stefanzweifel/changelog-updater-action@v1
        with:
          latest-version: ${{ github.event.release.name }}
          release-notes: ${{ github.event.release.body }}

      - uses: stefanzweifel/git-auto-commit-action@v7
        with:
          branch: main
          commit_message: Update CHANGELOG
          file_pattern: CHANGELOG.md
```

### The Full Pipeline

```
1. Merge PRs to main
1. CI validates (tests, PHPStan, style)
1. Create GitHub release with auto-generated notes
1. update-changelog.yml fires -> CHANGELOG.md updated -> committed to main
1. Packagist webhook fires -> package version published
1. Dependabot handles downstream updates for consumers
```

One human action: step 3. Everything else is automated.
