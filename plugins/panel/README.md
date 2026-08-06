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
5. Verdicts are committed artifacts in the branch under review.
6. Nothing starts until the charter is approved.
7. Verdicts may only narrow. The loop ends in silence.
8. A judgment that recurs becomes an oracle.
```

**Laws 1 and 4 are one idea, twice.** Law 1 is the principle — nobody approves their own work.
Law 4 is the mechanism that makes it structural rather than polite: a judge that cannot write what
it judges cannot have written what it approves. Read together, not separately.

**Law 1's "leader included" is aspiration in 0.1.0.** Judges are held structurally by an allowlist.
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

---

## Enforcement

```
Structural     tools: Read, Glob, Grep on judges.
               No escape found under adversarial probing.

Architectural  /verdict runs oracles in the parent session.
               Exit codes are harness-observed, never model-reported.

Not shipped    The parent's own write scope is unconstrained in 0.1.0.
               Author restraint from verdicts/ is convention, not enforcement.
```

---

## Install

Standalone.

```
/plugin install panel@the-foundry
```

---

## Use

```
/panel add gift card redemption at checkout
```

Answers questions until the goal is gradeable, writes `.claude/panel/charter.md`, and waits for
you to approve it. Declare the gates:

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
oracles.** A task with no mechanical checks gets taste ping-pong wearing a protocol.

Panel is worth exactly what its oracles are worth.

---

## The Kill Criterion

This plugin's premise is unproven: nobody has shown an adversarial panel beats disciplined
self-review per token on a solo developer's workload.

Verdicts are committed data. Instrument them — iterations to approval, oracle-caught versus
judge-caught, promotions per run. **If ten runs show no catches that self-review would have missed,
delete the plugin and keep `craft-oracle`.** That part has unconditional value.

---

## License

MIT
