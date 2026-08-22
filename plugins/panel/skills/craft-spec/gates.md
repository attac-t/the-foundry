# The two gates, and the draft they judge

## Drafting — how step 4 comes to exist

Every element derives from an earlier step. Nothing is invented here.

```
one entry point per driving-port intent          step 3   (not per HTTP route)
the receiver is the aggregate                    step 2
each chain link is one obstacle                  step 2
the return type is the need                      step 1
nothing else                                     — no parent, no place in the draft
```

Types in the draft are **provisional**. Step 7 may replace them, and a signature change re-opens
gate 1. That is expected — the draft is cheap precisely so it can be redrawn.

## Gate 1 — the signature draft

Empty bodies. An empty draft is free to discard; filled-in code is not.

**Do not read your own draft — write client code against it, from three callers.** Your own naming
always feels obvious.

Two things vanish once bodies exist, so the draft must expose them: whether the chain's order is a
real dependency or an invented one, and whether a step throws or returns a flag.

## Gate 2 — the cold read

A newcomer rebuilds the program's theory rather than reads it. Four timed tests — **locate,
understand, predict, change** — run by someone who wasn't here. `panel:newcomer` carries them.

**A regression in time-to-understand is a finding**, the same as a failing test.

> **If this step requires writing new documentation, the walk leaked.** Steps 0–5 already produced
> the theory. Step 10 publishes it.

