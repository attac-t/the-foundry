# Verdict 009 — newcomer — APPROVE

Charter: a green check is two claims
Reviewed: `feat/ground-evidence` @ **a6d8db0**. Gate 2, first cold read in this repository.
Recorded by the parent. Timings appended to `cold-read-log.md`.

| Test | Time | Route |
|------|------|-------|
| Locate | 1m | 2 greps, top hit, no browsing |
| Understand | 2m | one file, no second opened |
| Predict | 1m | answered verbatim by the text |
| Change | 4m | 3 files — answering *"would I know"* meant reading the gates |

| Sev | Where | Issue | Change | Principle |
|-----|-------|-------|--------|-----------|
| W | `craft-plugin-update:3` | `description:` and `## When` say "release a version"; half the file answers "your edits aren't running" — the symptom a reader arrives with | put the staleness clause in the description | discovery is by description; `bin/frontmatter.sh` exists one level up from this |
| W | `bin/versions.sh:19-24` | checks the two files *agree*, not that a bump *happened*; ship unbumped and every gate is green — the silent staleness the same document calls load-bearing | none available in-repo; name it as unguarded | a rule with no oracle is a wish |
| W | `bin/repeats.sh` scope | the only content gate covers `panel` and `pest`; `kernel` prose including the two shell commands is unchecked | note the exemption where the gates are listed | docs the gates do not run are untested code |
| N | `craft-plugin-update:40` | `ls ~/.claude/...` does not run as written on this repo's own platform | give a form both shells take | write for the reader's machine |

## What's Good

- `## What You Edit Is Not What Is Running` — the heading *is* the phrase searched with, so locate
  succeeded on the first grep. Keep it through any refactor.
- The scar (`0.6.2` reviewed against a `0.9.4` tree) is what made test 3 cost one minute, not five.
- `bin/*.sh` open with why-they-exist comments. Test 4 was answerable only because of those headers.

## Promote

- Assert that the two shell commands in kernel docs resolve — unverified strings in the one skill
  `CLAUDE.md` mandates.
- Widen `bin/repeats.sh` past `panel` and `pest`, or record why `kernel` is exempt.

## Disposition

Three fixed in `0af4526`; W2 named as unguarded in the document itself, since no oracle for it
exists here. Both `Promote` items partially taken: the prose gate now reaches the three kernel skills
this charter touches and the README says so; the shell commands remain unverified and say so.
