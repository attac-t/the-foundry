# Scheduling Evolve

Monthly is enough. The durability filter ignores anything younger than six months,
so running weekly just burns tokens to reach the same verdict.

---

## Pick the Right Mechanism

Claude Code offers three. Only two suit a job like this.

| Mechanism                    | Needs a session open? | Survives restart | Local files | Use for `evolve` |
|------------------------------|-----------------------|------------------|-------------|------------------|
| **Routines** (cloud)         | No                    | Yes              | Fresh clone | ✅ Yes           |
| **Desktop scheduled task**   | No                    | Yes              | Yes         | ✅ Yes           |
| **GitHub Actions**           | No                    | Yes              | Fresh clone | ✅ Yes           |
| **`/loop`**                  | Yes                   | 7-day expiry     | Yes         | ❌ No            |

> [!IMPORTANT]
> `/loop` is session-scoped and recurring loops expire seven days after creation. It
> is built for polling a deploy, not for a monthly job. A monthly `/loop` would fire
> perhaps twice and then vanish silently.

---

## Cloud (Routines)

Runs on Anthropic infrastructure whether or not your machine is on. Minimum
interval is one hour, which is far below what this needs.

```
/schedule
```

Then describe the cadence and the prompt:

> Run the `kernel:evolve` skill on the first of each month and open one PR per
> accepted change.

Routines get a fresh clone, so `evolve` reads the repo as a contributor would.

---

## Local (Desktop scheduled task)

Use this when the job needs your local tooling or credentials. Configure it in the
Claude Code desktop app's scheduled tasks, with the prompt:

> Invoke the `kernel:evolve` skill.

---

## CI (GitHub Actions)

The most reviewable option: the run leaves a log, and a PR is the natural output.

```yaml
name: Evolve
on:
  schedule:
    - cron: '17 6 1 * *'   # 06:17 on the 1st. Avoid :00 — see jitter.
  workflow_dispatch:
```

Pick a minute that is not `:00` or `:30`. The scheduler adds a deterministic offset
of up to 30 minutes to recurring jobs, so an on-the-hour cron is the least
predictable choice, not the most.

---

## Do Not Set `disable-model-invocation`

A scheduled fire only executes skills Claude is permitted to invoke on its own. A
skill marked `disable-model-invocation: true` arrives as plain text and does
nothing. `evolve` and `retrospect` both leave it unset for that reason.

---

## What a Good Run Looks Like

```
Scouted:    3 ecosystem changes, 1 survives the durability filter
Prosecuted: 2 deletion candidates
Verdict:    1 correction · 0 deletions · 0 additions
Budget:     kernel 32/32 · laravel-ddd 46/46 · playbook 29/29 · pest 11/11
```

And most months:

```
Verdict: 0 corrections · 0 deletions · 0 additions
```

That is the skill working. A month with nothing worth changing is the common case,
and a run that always finds something has stopped being a filter.
