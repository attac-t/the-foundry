# Plugins

## Bump the version — every time

After modifying **any** file inside a plugin, bump it via `craft-plugin-update`.

Both places: `plugin.json` **and** the plugin's entry in `.claude-plugin/marketplace.json`. Nothing
surfaces a mismatch — the plugin installs and reports the wrong version. `bin/versions.sh` exists
because this shipped.

Patch for a fix or docs. Minor for a new skill or command. Major for a break.

## Shipped code

A plugin that ships code declares `sh`, `awk` and `git`. Nothing else — a gate needing a parser
stops working on Alpine.

A plugin that ships no code has no gate. Green says nothing about whether its skills are still true.

## Stack plugins

Read the README before modifying one. Check whether it needs updating after.
