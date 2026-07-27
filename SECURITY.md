# Security Policy

## Reporting a Vulnerability

Report privately. Do not open a public issue.

[**Open a private security advisory**](https://github.com/attac-t/the-foundry/security/advisories/new)

Include what you can: the affected plugin and version, reproduction steps, and
the impact you see. You will get an acknowledgement within 7 days and an
assessment within 14.

Please give us a chance to ship a fix before disclosing publicly. Report in good
faith and we will credit you in the release notes unless you ask us not to.

---

## Supported Versions

The latest release of each plugin. Fixes ship forward, not as backports.

---

## What This Repository Executes

Worth understanding before you install anything, here or elsewhere.

The `kernel` plugin registers shell hooks that Claude Code runs automatically:

| Hook            | Fires on           | What it does                       |
|-----------------|--------------------|------------------------------------|
| `remember.sh`   | Session start      | Reads working memory, prints it    |
| `ground.sh`     | Session start      | Prints an instruction to Claude    |
| `anchor.sh`     | Every prompt       | Prints your current objective      |
| `recite.sh`     | Every prompt       | Prints a memory-update reminder    |
| `evaluate.sh`   | Every prompt       | Prints a skill-evaluation prompt   |
| `delegate.sh`   | Every prompt       | Prints a delegation reminder       |
| `consider.sh`   | After a file edit  | Prints an ADR reminder             |
| `verify.sh`     | Session stop       | Reads the blueprint. **Can block the stop** — see below |

Two shared helpers sit in `hooks/lib/` and are called by the hooks above rather
than by Claude Code: `resolve-memory.sh` (works out the branch memory path) and
`extract-objective.sh` (pulls the goal line out of `working.md`). Ten shell files
in total.

All ten are read-only. They read your git branch and files under
`.claude/memory/`, then write to stdout. They make no network calls and write no
files.

`verify.sh` is the one hook that does more than print. If your blueprint lists
in-progress tasks, it emits `{"decision": "block"}`, which tells Claude Code not to
end the turn until you finish, defer, or hand off. It changes control flow, not
your filesystem.

The programs they invoke are `git` and standard POSIX utilities — `cat`, `grep`,
`sed`, `sort`, `head`, `find`, `basename`, `dirname`, `pwd`, `command` — plus
[`jq`][jq] in `consider.sh`. If `jq` is absent, that hook exits quietly rather
than guess.

[jq]: https://jqlang.github.io/jq/

Read them yourself — they are short:
[`plugins/kernel/hooks/`](plugins/kernel/hooks/)

CI guards this on every pull request: ShellCheck over all ten files, and a check
that fails the build if a hook gains `curl`, `wget`, `nc`, `ssh`, `scp`, `rsync`,
an interpreter (`python`, `perl`, `ruby`, `osascript`), or `/dev/tcp`.

That check is a regression guard, not a sandbox — a determined script could still
reach the network some other way. The real assurance is that these files are short
enough to read in a sitting, which is why they are linked above rather than
summarised.

The other three plugins ship skills only — markdown, no executable code.

---

## Trust Model

Plugin hooks execute on your machine with your permissions. That is true of every
Claude Code plugin, from any marketplace. Before you install one:

- Read its hooks. If there are none, there is nothing to execute.
- Pin what you depend on. A moving `main` is a moving target.
- Prefer plugins whose executable surface you can read in a sitting.

We hold this repository to that standard. Hold us to it.
