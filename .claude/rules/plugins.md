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

**An agent can move it.** `-y` exists for exactly this caller — the help says it is required when
stdin or stdout is not a TTY.

```sh
claude plugin update kernel@the-foundry -y
```

**What needs a person is the restart, not the pull.** The command says so: *restart required to
apply*. A session keeps the skills it loaded, and no pull reaches them.

**So ask for the restart, and say why.** An agent that bumps, pulls and carries on has the new
version on disk and the old one in memory. That looks finished, which is what makes it worth
saying.

That is the same failure as a rule naming a skill nobody can invoke.

## Shipped code

A plugin that ships code declares what it needs, and never more than POSIX plus `git`. **No parser
and no runtime** — a gate reaching for one stops working on Alpine.

A plugin that ships no code has no gate. Green says nothing about whether its skills are still true.

Panel ships code now, and only this: the review chain refusing a prior verdict that is not there. That
enforces a contract Panel already had. It does not make Panel a planner or a coordinator.

## Stack plugins

Read the README before modifying one. Check whether it needs updating after.
