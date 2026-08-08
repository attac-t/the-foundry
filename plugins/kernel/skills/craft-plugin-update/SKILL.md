---
name: craft-plugin-update
description: Release a plugin version, and why your edits are not running yet. Bump plugin.json and the marketplace manifest, reinstall, then commit.
---

# Skill: Craft Plugin Update

> "Bump, commit, push. In that order."

## When

Releasing a plugin version — **or when a change you just made is not taking effect.** Same skill,
because they are the same mechanism.

## What You Edit Is Not What Is Running

**A session runs an installed copy.** Installing stages the plugin into a cache directory named for
its version, so a skill you just rewrote keeps behaving exactly as it did before you touched it:

```
~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/     ← what the session loads
<repo>/plugins/<plugin>/                                      ← what you edited
```

True even when the marketplace points at the repository. That decides where copies come *from*; it
does not make the copy live.

**The bump is what gives an update somewhere to land** — the cache directory is named by version, so
shipping without one leaves the old directory serving. Load-bearing, not bookkeeping.

```bash
claude plugin update <plugin>@<marketplace>
```

Then **restart the session**; skills load at startup. Confirm by looking for a directory named after
the new version — `~` is not portable, so spell the path for your own shell:

```bash
ls "$HOME/.claude/plugins/cache/<marketplace>/<plugin>/"          # bash, zsh
```
```powershell
Get-ChildItem "$env:USERPROFILE\.claude\plugins\cache\<marketplace>\<plugin>\"
```

Nothing verifies those commands. They are strings in a document. Run them; do not trust them.

**Editing a plugin and testing it in the same session is the trap.** The files on disk changed, so
the edit looks applied, and every agent keeps reading the copy. One project ran a full review cycle
against `0.6.2` while its tree stood at `0.9.4` — every finding valid, none about the current code.

## The Protocol

1. **Bump version in both places** — `plugin.json` *and* the plugin's entry in
   `.claude-plugin/marketplace.json`
   - Patch: bug fixes, docs
   - Minor: new skills, features
   - Major: breaking changes

   The manifest is the one that gets forgotten, and nothing surfaces the mismatch: the plugin
   installs fine and reports the wrong version. A repository that has been bitten by this usually
   grows a check comparing the two files; write one if yours has not.

   **Such a check compares the two files; it cannot see that a bump was owed.** Ship a plugin edit
   with no version change and a manifest check stays green while the old copy keeps serving — the
   silent staleness below. You are the guard for that one.

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
