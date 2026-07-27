---
name: craft-plugin-update
description: Releasing a plugin version. Bump, validate, tag.
---

# Skill: Craft Plugin Update

> "Bump, validate, tag. In that order."

## When

After changing any file inside a plugin. Every time.

## The Single Source of Truth

`plugin.json` owns the version. Nothing else.

At install time `plugin.json` wins over the marketplace entry, so a `version` in
both is drift waiting to happen. Leave it out of `marketplace.json`.

## The Protocol

1. **Bump** `version` in `.claude-plugin/plugin.json`

2. **Validate** — the plugin, then the marketplace

   ```bash
   claude plugin validate ./plugins/<name> --strict
   ```

   ```bash
   claude plugin validate .
   ```

   `--strict` promotes warnings to errors. Use it. A misspelled manifest field
   loads fine at runtime and silently does nothing.

3. **Commit** in Commitizen format

   ```
   chore(<plugin>): bump to <version>
   ```

4. **Tag** — only if the plugin is a dependency of another

   ```bash
   claude plugin tag --push
   ```

   Tags are `<plugin>--v<version>`. Version constraints resolve against them.
   Without a tag, `{ "name": "x", "version": "~2.1.0" }` has nothing to match.

## The Versioning

| Change            | Bump  | Example       |
|-------------------|-------|---------------|
| Typo, docs        | Patch | 1.0.0 → 1.0.1 |
| Skill refinement  | Patch | 1.0.1 → 1.0.2 |
| New skill         | Minor | 1.0.0 → 1.1.0 |
| New dependency    | Minor | 1.0.0 → 1.1.0 |
| Renamed skill     | Major | 1.0.0 → 2.0.0 |
| Removed skill     | Major | 1.0.0 → 2.0.0 |

Renames and removals are breaking. A user's muscle memory is your API.

## The Anti-Patterns

- **Skipping the bump**: Users get nothing. Claude Code caches by version string,
  so new commits alone change nothing.
- **Eyeballing frontmatter**: Run the validator. A skill with no frontmatter is
  invisible, and it looks fine in the diff.
- **Version in two places**: `plugin.json` only.
- **Major for a typo**: Read the table.

## The Output

State: "Bumped `<plugin>` to `<version>`. Validated."
