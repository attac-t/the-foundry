# Plugins

## Bump the version — every time

After modifying **any** file inside a plugin, bump it via `craft-plugin-update`.

Both places: `plugin.json` **and** the plugin's entry in `.claude-plugin/marketplace.json`. Nothing
surfaces a mismatch — the plugin installs and reports the wrong version. `bin/versions.sh` exists
because this shipped.

Patch for a fix or docs. Minor for a new skill or command. Major for a break.

Every plugin change edits `marketplace.json`, so two plugin branches off `main` collide there by
construction. Open the second on the first via `craft-pr-stack`.

## Shipped code

A plugin that ships code declares `sh`, `awk` and `git`. Nothing else — a gate needing a parser
stops working on Alpine.

A plugin that ships no code has no gate. Green says nothing about whether its skills are still true.

Panel ships code now, and only this: the review chain refusing a prior verdict that is not there. That
enforces a contract Panel already had. It does not make Panel a planner or a coordinator.

## Stack plugins

Read the README before modifying one. Check whether it needs updating after.
