---
name: decide-test-merit
description: When a test earns its line, and when to cut it. Removal is the test of a test.
---

# Skill: Decide Test Merit

> "A test that cannot fail is a comment that costs a second."

`craft-test` decides whether a behaviour deserves a test. This decides whether a test you already
have deserves its line.

## The Decision

**Keep it when:**

- Breaking the code it guards turns it red
- It is the only check that would notice
- It names the mechanism where a neighbour names only the outcome
- It pins something documented — a code, a path, a format

**Cut it when:**

- A neighbour fails first, for the same reason
- It walks the same branch with different inputs
- It asserts a thing exists, and the next check reads that thing
- It passes without the mechanism it claims to prove ever running

## The Heuristic

Ask: *"If I delete this line, what goes red?"*

Nothing → it was never a test.

## The Quick Test

| Ask | Answer | Then |
|-----|--------|------|
| Break the code on purpose — does it fail? | No | It is not guarding. Fix it or cut it |
| Delete it — is every deliberate break still caught? | Yes | Cut it |
| Does another check fail first, same cause? | Yes | Cut the later one |
| Would anything else notice? | No | Keep it, whatever it costs |

## Aim The Break

A break must change the lines you meant and no others. Prove it before you trust it: apply it, count
the changed lines, and check the result still parses.

**A break that fires in two places tests neither.** One that must fire in several says so on its own
line — otherwise the next reader cannot tell design from accident.

Moving code silently unaims every break that named it. A harness worth having reports *the break did
not apply* rather than passing.

## Passing For The Wrong Reason

Worse than a missing test, because every instrument scores it as coverage — including the person who
wrote it. A gap is known. A false negative is not.

**The tell:** you cannot name the line that would have to change to turn it red.

## Two Altitudes, Not Three

Split behaviour from mechanism **only when the behaviour check can pass without the mechanism
running**. One extra check, not a family — a third, restating either, is triplication reading as
thoroughness.

## When The Failure Cannot Be Forced

Some shapes will not arrange portably: a permission the filesystem does not record, a race, a clock.
Keep the guard and say so.

**A guard with an untestable case is honest.** A guard with a break that proves nothing is not — it
reads as covered, which is worse than reading as absent.

## The Anti-Patterns

| Don't | Do | Why |
|-------|----|-----|
| Count checks | Count what only they catch | Suites grow checks faster than coverage |
| Cut on a hunch | Cut, then re-run the breaks | The audit decides, not taste |
| Keep it "just in case" | Name the case, or cut it | An unnamed case is not a case |
| Assert existence, then read | Read it | The read already fails on absence |
| Trust a green suite never seen red | Break it on purpose | Green is evidence only if red was possible |
