# Plugins

What a plugin owes when it changes.

## Bump the version — every time

After modifying **any** file inside a plugin, bump it via `craft-plugin-update`.

One place: the plugin's own `plugin.json`. `marketplace.json` names plugins and where they live, and
carries no version — the field is optional and Claude Code falls back to `plugin.json`.

Patch for a fix or docs. Minor for a new skill or command. Major for a break.

**That is why two plugin branches no longer collide.** The version used to sit in a shared file, so
branches touching different plugins conflicted anyway and work was stacked for packaging reasons.
`craft-pr-stack` is for work that genuinely builds on work.

## A bump nobody pulled is a bump nobody has

**A version in `plugin.json` changes nothing in the session that wrote it.** The installed copy
comes from the marketplace cache, and the cache does not move on its own.

Two commands, and only a person can run them:

```
/plugin marketplace update the-foundry
/reload-plugins
```

**Ask for them after a bump.** An agent that bumps and carries on holds the new rule from memory
while the session runs the old one.

That is the same failure as a rule naming a skill nobody can invoke.

## A capability owes the line that reaches it

**Ship the mechanism and the process step together, or the mechanism is decoration.**

Three shipped here and none was reached:

| Built | Never called |
|---|---|
| the run, its pointer and its claim | no rule told a worker to open one |
| a readiness answer refusing six ways, each naming a remedy | the command a person runs says `joined.` and exits 0 |
| an exclusive claim — one host takes it, a second is refused | the scheduling scripts say `claim` zero times |

**Each was built, tested and green.** A suite proves a function works. **It cannot prove anything
calls it.**

**So say who calls it, in the same change.** A rule, a command, a step in a README — whichever
reaches a worker at the moment it applies. **If nothing does, the work is not finished.**

## Shipped code

A plugin that ships code declares what it needs, and never more than POSIX plus `git`. **No parser
and no runtime** — a gate reaching for one stops working on Alpine.

A plugin that ships no code has no gate. Green says nothing about whether its skills are still true.

Panel ships code now, and only this: the review chain refusing a prior verdict that is not there. That
enforces a contract Panel already had. It does not make Panel a planner or a coordinator.

## Stack plugins

Read the README before modifying one. Check whether it needs updating after.
