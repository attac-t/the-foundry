# Plugins

What a plugin owes when it changes.

## Bump the version — every time

After modifying **any** file inside a plugin, bump it via `craft-plugin-update`.

One place: the plugin's own `plugin.json`. `marketplace.json` names plugins and where they live, and
carries no version — the field is optional and Claude Code falls back to `plugin.json`.

Patch for a fix or docs. Minor for a new skill or command. Major for a break.

**Below 1.0, a break bumps the minor.** Four plugins here are. A major there reads as *this is stable now*, and a break is the proof against that.

**Leaving 1.0 is a person's call, in writing.** It says the shape has settled, and nothing in a diff can know that.

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

## What a pull reads from is the host's record, never this repository's

A checkout can declare `source: github` while the machine has that same marketplace registered as a
**directory pointing at the checkout itself**. The host's record is the one a pull obeys, and
nothing else says so.

**Then a pull takes the working tree, on whatever branch is out.** It happened here on 20 September:
`floor 0.87.1` installed from an open branch while that branch's audit was still running at 250 of
273 breaks. It graded green ten minutes later. A red one would have installed the same way.

```sh
sh plugins/floor/lib/plugins.sh declared .
```

Silent when the two agree, and it names both when they do not. **Ask it before you pull on a
branch.** [#943](https://github.com/attac-t/the-foundry/issues/943) owns the rest.

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
