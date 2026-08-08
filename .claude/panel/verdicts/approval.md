# Approval — a green check is two claims

**Branch** `feat/ground-evidence` · **Approved at** `7c57a18` · **Panel** `panel:author` (author) ·
`panel:adversary` (gate 1) · `panel:newcomer` (gate 2)

| Round | Gate |
|-------|------|
| 009 | gate 2 — **APPROVE**, 3 W 1 N. First cold read in this repository |
| 010 | gate 1 — REVISE, 1 C 5 W. The widened scope reached one of the two files that state it |
| 011 | gate 1 — **APPROVE**, 1 W. Ratchet binding |

## Rationale

The Critical was the second occurrence of one drift — a gate command re-specified in two files, each
correct alone. It is now the only thing in the chain that runs first: `bin/gates-agree.sh` compares
the workflow against `README`'s line, and was audited by deleting a step, which it named.

`ground-evidence` ships with its own provenance disowned. `examples.md` tells the reader the corpus
is the author's and not theirs to audit — the fix that made the skill's own evidence obey the skill's
own rule about evidence you do not own.

The charter records that the reason first given for the registration gate was false, and keeps the
gate on the true one. A charter that can say that is worth more than one that was right.

## Residual risks

1. **`bin/gates-agree.sh` compares command strings, not behaviour** — reordering `gates.yml` is
   invisible, since the comparison sorts.
2. ~~It passes vacuously on an empty selection~~ — closed after issuance; it now refuses when the
   README anchor is missing, verified by removing it.
3. ~~`README` still says five unrun workflow steps~~ — closed after issuance. All three counts
   dropped in favour of *every step in `gates.yml`*.
4. **The near-copy across plugins survives one word apart.** `ground-mechanism/examples.md` against
   `craft-oracle`. The charter declares this ungateable; the ratchet barred raising it.
5. ~~`kernel/README.md` lists `evaluate` under Skills; it is a command~~ — closed after issuance.
6. **Third consecutive approval shipping a CI that has never run.** Nine steps, zero executions;
   whether `python` resolves on `ubuntu-latest` is unknown. **The judge's position: a fourth
   recording is not a residual risk, it is a decision nobody has made.**
7. **`bin/versions.sh` cannot see a missing bump.** Whether `7c57a18` carried kernel's bump is
   unverified by any gate — the judge had no shell and could not read history.
8. **The judge's skills were plugin cache `0.6.2` against a `0.9.x` tree** — the scar deliverable 3
   documents, recurring inside the run that documents it. Every citation was read from the working
   tree by absolute path.
9. **Deliverable 1 is unmeasurable here.** Whether `ground-evidence` changes how a session reads a
   result rests on one row in `cold-read-log.md`, which the log itself calls noise.

## Closed

Chris Attard — pending, on the charter.

*Recorded verbatim from the judge. The charter is approved; this line is the one thing left, and it
is not the author's to write.*
