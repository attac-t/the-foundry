# Verdict 011 — adversary — APPROVE

Charter: a green check is two claims
Reviewed: `feat/ground-evidence` @ **7c57a18**. Gate 1, round two. Ratchet binding.
Recorded by the parent.

**Method note from the judge:** no Bash this round — `Read`, `Glob`, `Grep` only. `git diff` was not
run; anything requiring history is marked unverified below.

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| W | `README:85` | "**five** workflow steps… none of which has ever executed" — this round added a sixth; `gates.yml` holds nine `run:` steps and none has run, so the claim is true of all nine | drop the count | `ground-evidence` — quote the scope too; scope is the half that rots. Fix-induced |

**010's Critical is closed.** `gates.yml` carries the widened scope verbatim with `README:58`; both
files now say three kernel skills and no further. W1 replaced rather than reworded —
`ground-mechanism/examples.md` is the *why*-comment open set, which `craft-oracle` does not carry.
W2 gone. W3 genericised. W4 closed: all 32 skills indexed. The charter challenge is taken in a form
that records the false reason instead of quietly replacing it.

## What's Good

- `bin/gates-agree.sh:25-28` — the selector carries the bug it caused, inside the function that fixes
  it. A refactor back to fence-ordering silently reselects the install snippet.
- `ground-evidence/examples.md:3-5` — the corpus disowns itself: *"shapes to recognise rather than a
  record you can go and audit."* Stronger than the citation it replaced.
- `craft-plugin-update:71-73` — states the limit of the very check it tells you to write, in the
  document that would otherwise be quoted as proof.

## Promote

- **Accumulation, not instance.** "One machine, once; `gates.yml` has never executed" is now the
  **third consecutive approval** carrying it. Two steps, then five, now nine. Resolve the billing
  lock or move enforcement to a pre-commit hook — *a fourth recording is not a residual risk, it is
  a decision nobody has made.*
- **Detect the cache skew.** The judge ran panel `0.6.2` against a `0.9.4` tree, second recorded
  occurrence, and the exact scar deliverable 3 documents. The charter scopes out *automating the
  reinstall*; it does not scope out reading the two versions and refusing.

## Challenge

- **The brief said "ten `gates.yml` steps".** Nine are `run:` steps; ten counts `uses: checkout`,
  which is not a gate. `README` said five, the charter said five *panel* steps. **Three counts for
  one fact, in a charter about checks stating their subject.**
- **`bin/gates-agree.sh` passes vacuously on an empty selection.** Lose the README anchor and the
  workflow's `run:` keys and it prints `PASS — 0 gate commands`.
- SPLIT reconsidered and declined: no `decide-boundary` tell fires.
- **Unverified:** that `7c57a18` carried kernel's bump. `versions.sh` proves agreement, not that a
  bump was owed, and the judge had no history.

## Disposition

Approved. `verdicts/approval.md` recorded verbatim.

Closed after issuance: all three counts dropped in favour of *every step in `gates.yml`* — the number
was stated three times across two files and was wrong in all three by the time anyone looked. The
empty-selection guard is in, verified by deleting the README anchor and watching it refuse rather
than agree with nothing. `kernel/README.md` no longer files the `evaluate` **command** under Skills.

Both `Promote` items are escalated to the human rather than built: one is a spending decision, and
the other would add an unjudged gate under a closed approval.
