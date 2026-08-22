# Plugins

## Bump the version — every time

After modifying **any** file inside a plugin, bump it via `craft-plugin-update`.

One place: the plugin's own `plugin.json`. `marketplace.json` names plugins and where they live, and
carries no version — the field is optional and Claude Code falls back to `plugin.json`.

Patch for a fix or docs. Minor for a new skill or command. Major for a break.

**That is why two plugin branches no longer collide.** The version used to sit in a shared file, so
branches touching different plugins conflicted anyway and work was stacked for packaging reasons.
`craft-pr-stack` is for work that genuinely builds on work.

## Shipped code

A plugin that ships code declares `sh`, `awk` and `git`. Nothing else — a gate needing a parser
stops working on Alpine.

A plugin that ships no code has no gate. Green says nothing about whether its skills are still true.

Panel ships code now, and only this: the review chain refusing a prior verdict that is not there. That
enforces a contract Panel already had. It does not make Panel a planner or a coordinator.

## Stack plugins

Read the README before modifying one. Check whether it needs updating after.
