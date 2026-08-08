---
name: craft-plugin-update
description: Release a plugin version, and why your edits are not running yet. Bump plugin.json and the marketplace manifest, reinstall, then commit.
---

# Skill: Craft Plugin Update

> "Bump, commit, push. In that order."

## When

Releasing a plugin version — **or when a change you just made to a plugin is not taking effect.**
Those are the same skill because they are the same mechanism, which is not obvious until it costs
you an afternoon.

## What You Edit Is Not What Is Running

**A session runs an installed copy, not your working tree.** Installing stages the plugin into a
cache directory named for its version and pinned to a commit, so a skill you just rewrote keeps
behaving exactly as it did before you touched it:

```
~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/     ← what the session loads
<repo>/plugins/<plugin>/                                      ← what you edited
```

This holds even when the marketplace points at the repository itself. Pointing at a directory
decides *where copies come from*; it does not make the copy live.

**The version bump is what gives the update somewhere to land.** The cache directory is named by
version, so shipping without a bump leaves the old directory in place and the old behaviour running.
That makes the bump load-bearing rather than bookkeeping, which is not obvious from the outside.

```bash
claude plugin update <plugin>@<marketplace>
```

Then **restart the session** — skills load at startup. To confirm it landed, look for a directory
named after the new version. Give the path in a form your shell takes; `~` is not portable, and the
machine you are on may not be the one the example was written on:

```bash
ls "$HOME/.claude/plugins/cache/<marketplace>/<plugin>/"     # bash, zsh
```

```powershell
Get-ChildItem "$env:USERPROFILE\.claude\plugins\cache\<marketplace>\<plugin>\"
```

**Nothing here verifies that those commands are right.** They are strings in a document, and the one
gate that reads this repository's prose does not cover `kernel`. Run them; do not trust them.

**Working on a plugin and testing it in the same session is the trap.** Edits look applied because
the files on disk changed; every agent keeps reading the copy. One project ran an entire review
cycle against version `0.6.2` while its tree stood at `0.9.4` — every finding valid, none of them
about the current code. Take the tree as the source of truth and the loaded skills as *stale until
reinstalled*, or verify the running version before trusting a result.

## The Protocol

1. **Bump version in both places** — `plugin.json` *and* the plugin's entry in
   `.claude-plugin/marketplace.json`
   - Patch: bug fixes, docs
   - Minor: new skills, features
   - Major: breaking changes

   The manifest is the one that gets forgotten, and nothing surfaces the mismatch: the plugin
   installs fine and reports the wrong version. `bin/versions.sh` exists because this shipped.

   **It checks the two files agree — not that a bump happened.** Ship a plugin edit with no bump and
   every gate stays green while the old copy keeps serving, which is exactly the silent staleness
   below. Unguarded, and worth knowing you are the guard.

2. **Update changelog** (if exists)
   - Date + version header
   - Brief summary of changes

3. **Commit with conventional format**
   ```
   chore({plugin-name}): bump to {version}
   ```

4. **Push and merge** to main

## The Versioning

| Change Type        | Bump  | Example       |
|--------------------|-------|---------------|
| Bug fix            | Patch | 1.0.0 → 1.0.1 |
| New skill          | Minor | 1.0.0 → 1.1.0 |
| Skill refinement   | Patch | 1.0.1 → 1.0.2 |
| Breaking change    | Major | 1.0.0 → 2.0.0 |
| Docs only          | Patch | 1.0.0 → 1.0.1 |

## The Anti-Patterns

- **Forgetting the bump**: Merge without version update
- **Wrong bump type**: Major for a typo fix
- **No commit message**: Generic "update" message

## The Output

State: "Bumped `{plugin}` to `{version}`. Pushed."
