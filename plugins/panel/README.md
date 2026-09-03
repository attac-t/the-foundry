# Panel

Adversarial agent teams. Verification that cannot be self-issued.

**It is not a system that builds systems. It is a system that refuses to build the wrong one.**

---

## Philosophy

A single agent writes the work and decides it is done. The blind spot that writes the bug writes
the test that misses it.

Instructing an agent to critique its own work is one context wearing a different hat, and a hat is
not a second opinion. Panel supplies the second context — and makes it structurally incapable of
approving what it judges.

---

## The Laws

```
1. No agent approves its own work — the leader included.
2. Mechanical claims reduce to a command. Judgments carry severity.
3. Only failing commands and Criticals block.
4. A judge never writes what it judges.
5. Verdicts are written to `.claude/panel/verdicts/`, which this repository ignores.
6. Nothing starts until the charter is approved.
7. Verdicts may only narrow. The loop ends in silence.
8. A judgment that recurs becomes an oracle.
```

**Laws 1 and 4 are one idea, twice.** Law 1 is the principle — nobody approves their own work.
Law 4 is the mechanism that makes it structural rather than polite: a judge that cannot write what
it judges cannot have written what it approves. Read together, not separately.

**Law 1's "leader included" is still aspiration.** Judges are held structurally by an allowlist.
The parent's own write scope is not constrained yet — see Enforcement. The most strongly worded law
is currently the least enforced, and it would be dishonest to state it without saying so.

Law 8 is why this gets cheaper. The first time a judge argues about dependency direction it costs a
review round. Once promoted to a forbidden-import check, it costs an exit code — forever.

---

## The Loop

```
charter ──▶ [ APPROVED BY A HUMAN ]
                  │
                  ▼
               author ──── writes src/ + tests/
                  │
                  │ commit
                  ▼
           /verdict ──── runs the gates; the harness reads exit codes
                  │
                  ▼
             adversary ──── tools: Read, Glob, Grep. Nothing else.
                  │
          ┌───────┼───────────┐
          ▼       ▼           ▼
       REVISE   SPLIT      APPROVE ──▶ ■ silence
                  │                 residual risks recorded
                  └──▶ back to the charter — the work was fine,
                       the boundary was wrong
```

**SPLIT is the judgement the gates cannot make.** Every oracle can pass and every acceptance clause
be met while the charter still held three projects. `decide-boundary` carries the tells — the same
shape a third time, one file with two unrelated reasons to change, a test needing setup from a
concern it doesn't test. All three roles load it, because the tells fire at different times: the
charter gate sees none of them, the author sees them first, the judge sees them last and dearest.

---

## Enforcement

```
Structural     tools: Read, Glob, Grep on judges.
               No escape found under adversarial probing.

Mechanical     bin/verdicts.sh refuses a round claiming a prior verdict
               that no file records. Fail closed, exit 1.

Architectural  /verdict runs oracles in the parent session.
               Exit codes are harness-observed, never model-reported.

Not shipped    The parent's own write scope is unconstrained.
               Author restraint from verdicts/ is convention, not enforcement.
```

---

## Looking back

A verdict says whether the work is good. It does not say whether the review was.

`kernel:retrospect` asks that, and needs no Panel. Where Panel is installed, the same judge that
refused the work is the one who can say what the refusal cost — and `bin/brief.sh` hands any model
the role to do it in.

**A panel that never reviews itself is a panel nobody has checked.**

---

## Install

Standalone.

```
/plugin marketplace add attac-t/the-foundry
/plugin install panel@the-foundry
```

---

## Use

```
/panel add gift card redemption at checkout
```

Answers questions until the goal is gradeable, writes `.claude/panel/charter.md` — untracked —
and waits for you to approve it. Declare the gates:

```yaml
# panel.yml
judges:
  - panel:adversary
gates:
  - name: tests
    command: composer test
  - name: types
    command: vendor/bin/phpstan analyse
```

Then:

```
/verdict
```

Runs the gates, hands the output to the adversary, records a verdict under `verdicts/`.

---

## The Walk

`craft-spec` is the method the author follows: eleven steps from business need to code, bracketed by
two gates. Step 4 judges the shape before any body exists — cheapest possible verdict. Step 10 hands
the finished work to `panel:newcomer`, who reads it cold and times how long understanding takes.

It governs code that **decides**. On projections — reports, transforms, rendering — it idles.

---

## Memory

Judges read `verdicts/` before forming a finding. Raised three times, it becomes a promotion
candidate instead of a fourth finding. Approved over three times, a residual risk has stopped being
residual.

Gate 2's timings append to `verdicts/cold-read-log.md`. **Slop is invisible in any single diff and
obvious across forty** — that column is the only instrument that sees it.

---

## When Not To Use It

Most of the time.

A panel is at minimum three contexts, multiplied by loop iterations. Convene when the work is
**high criticality and low reversibility**, or unattended — and **only when the task has real
oracles.** With no mechanical checks, the loop degenerates into taste ping-pong on a schedule.

Its ceiling is the quality of its gates.

---

## The Kill Criterion

This plugin's premise is unproven: nobody has shown an adversarial panel beats disciplined
self-review per token on a solo developer's workload.

Instrument the verdicts — iterations to approval, oracle-caught versus judge-caught, promotions per
run. **If ten runs show no catches that self-review would have missed, delete the plugin and keep
`craft-oracle`.** That part has unconditional value.

**Nothing can be instrumented yet, and this said the opposite.** It claimed verdicts were committed
data. `.gitignore` holds `.claude/panel/` — thirty-seven verdicts have been written here and one is
tracked, by accident. So a verdict dies with the branch, no run can count them, and nothing outside
the session that produced one can read it.

**That is why a `Judged:` clause has never been satisfied.** #332 owns producing a verdict floor can
read, and four closed issues — #67, #70, #75 and #77 — each carry a `Judged:` box waiting on it.

---

Needs: Claude Code CLI, `sh`, `awk`, `sed`, `find`, `sort`. No `git`, no Python, no Node,
no `jq`.

## License

MIT
