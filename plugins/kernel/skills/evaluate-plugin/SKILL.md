---
name: evaluate-plugin
description: How to verify the Cognitive OS is functioning correctly.
---

# Skill: Evaluate Plugin

> "A test that cannot fail measures nothing."

## The Principles

- **Falsifiable**: every check names what failure looks like. "It should work" is not
  an expectation.
- **Observable**: pass or fail from something you can see — a file, an exit code, text
  in the transcript. Not from a feeling that the mindset is present.
- **Two-sided where possible**: a hook that fires on everything is as broken as one
  that never fires. Test the negative case.

## The Suite

Run each. Record pass or fail with the evidence.

### 1. Structure

```bash
claude plugin validate ./plugins/kernel --strict
```

| | |
|---|---|
| **Pass** | Exit 0 |
| **Fail** | Any error, or a warning under `--strict` |

### 2. Grounding fires at session start

Start a fresh session and read the first system output.

| | |
|---|---|
| **Pass** | An instruction to invoke `kernel:ground` appears before Claude replies |
| **Fail** | Nothing appears — `remember.sh` or `ground.sh` is not registered or not executable |

### 3. The objective is anchored

Set a goal, then send an unrelated prompt.

| | |
|---|---|
| **Pass** | Your objective is echoed above the new prompt |
| **Fail** | The goal appears nowhere; `anchor.sh` is silent |

### 4. Skills are forced, not hoped for

Send a prompt that needs implementation.

| | |
|---|---|
| **Pass** | Claude lists skills with YES/NO before touching code |
| **Fail** | Claude starts editing with no evaluation block — `evaluate.sh` is not firing |

### 5. The ADR reminder discriminates

The two-sided one, and the most informative.

| Action | Expected |
|---|---|
| Edit a source file (`.php`, `.ts`, `.py`) | ADR reminder appears |
| Edit a `.md`, `.json`, or a file under `tests/` | **No** reminder |

| | |
|---|---|
| **Pass** | Both hold |
| **Fail** | Neither fires (hook dead), or **both** fire (`jq` missing, or the skip pattern is broken — it fires on everything) |

### 6. Memory is branch-scoped and current

```bash
ls .claude/memory/"$(git branch --show-current)"/
```

| | |
|---|---|
| **Pass** | `working.md` exists and its Goal matches what you are actually doing |
| **Fail** | Directory missing, or the Goal describes finished work — recitation has lapsed |

### 7. Stopping is guarded

With at least one `in-progress` row in `blueprint.md`, end the turn.

| | |
|---|---|
| **Pass** | The stop is blocked, naming the count of unfinished tasks |
| **Fail** | The turn ends silently — `verify.sh` is not registered |

### 8. The voice is active

Ask for an opinion on a mediocre design.

| | |
|---|---|
| **Pass** | A position, stated plainly |
| **Fail** | "You might want to consider…" — the output style is not applied |

## The Output

```
Structure   PASS
Grounding   PASS
Anchor      FAIL — objective absent from prompt 3
...
7/8 passing. Broken: anchor.
```

Report the failing check and its evidence. Do not summarise a partial pass as
working.

## The Anti-Patterns

- **Circular expectations**: "Run `/blueprint`; it should load the blueprint."
- **Escape hatches**: "…if configured" makes a check unfalsifiable.
- **One-sided hook tests**: firing always looks like firing correctly.
- **Declaring health from a subset**: 7/8 is a failure with a number attached.
