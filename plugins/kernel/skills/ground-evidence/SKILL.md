---
name: ground-evidence
description: What a green check does not prove. How to read a result before believing it.
---

# Skill: Ground Evidence

> "It passed" and "it looked at your work" are different sentences. One of them is printed.

## When

Every time a check comes back green and you are about to quote it as evidence.

## The Standard

- **A pass is two claims.** *The command succeeded* is on screen. *The command was aimed at the
  thing* is not, and it is the one that fails.
- **Assert an exact status, never "not zero".** A deleted script, a syntax error and a segfault are
  all "not zero". A negative test that accepts any failure accepts its own absence.
- **Make the check state its subject.** A number — files read, assertions run, components seen — and
  then read the number. Unstated coverage is coverage nobody checked.
- **Selecting the input is part of the check.** Whatever chooses the files can exclude precisely the
  work under review, and it usually does, because a check runs when its subject is new.
- **Fail for a named reason.** A status says something went wrong, never which thing. Where the
  reason carries the meaning, assert a fragment of the message too.

## The Check

Ask before quoting a green result:

- If I deleted the thing under test, would this still pass?
- If I broke the check itself, which assertion turns red? If none, it measures nothing.
- What did it actually open — and is that count on screen, or am I assuming it?
- Did it fail for the reason I claim, or merely fail?
- Is the evidence mine to keep? Anything outside the repository can change without telling you.

## The Tells

| Tell | Reading |
|------|---------|
| the count matches the arguments, not the work | it reported what it was handed |
| a negative case passes before the feature exists | absence is satisfying the assertion |
| every fixture shares one shape | they encode the author's guess about the input |
| the check has only ever run on examples | the real artifact has constructs the examples lack |
| a status is quoted with no message beside it | which branch fired is unknown |
| the evidence lives somewhere you do not control | it stops being evidence silently |

**A check nobody has broken on purpose is a check nobody has tested.**

## Two Ways To Be Wrong

| | Fix |
|---|---|
| the check is wrong | debug it — the ordinary case, and the one people expect |
| the check is right and pointed elsewhere | far more common, and it looks exactly like success |

## The Anti-Patterns

| Don't | Do | Why |
|-------|----|-----|
| `expect non-zero` | expect the status you mean | a missing binary satisfies it |
| Quote a pass without its scope | quote the count too | scope is the half that rots |
| Trust the fixtures alone | run it on the live artifact | fixtures inherit your blind spot |
| Let it skip what it cannot read | fail, and name the file | silence reads as coverage |
| `cmd \| tail -1; echo $?` | capture, then test | that status belongs to `tail` |
| Cite a corpus you do not own | copy its shape into a fixture | someone else's repository moves |

## Real-World Examples

See [examples.md](examples.md).
