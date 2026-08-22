---
name: craft-sh
description: Crafting a shell script that reads like prose. One story in main, one job per function, early returns, and the ways a shell lies to you.
---

# Skill: Craft Sh

> "A script you must read top to bottom is a script nobody reads."

Shell is no excuse. What makes a class readable makes a script readable.

## The Shape

`main` at the top. `main "$@"` at the bottom. Everything between is detail.

```bash
main() {
    read_arguments "$@"
    locate_worktree
    refuse_main_checkout

    ensure_herd_serves
    ensure_database_answers
    point_env_at_site
    report
}
```

Seven lines, the whole story. The test: **can a stranger describe the script after reading only
`main`?** If not, a name is wrong or a step does two jobs.

## The Standard

1. **One job per function, and few lines.** If the name needs "and", split it.
   **Length is the signal.** When a function grows, the verbosity has already started — that is the
   moment another function is merited, not once it is unreadable. The test is the call site:
   `fetch_objects; check_out_ref; point_at_origin` reads as English. A body you have to assemble does
   not.
2. **Early return. Never `else`.** Guard, return, carry on. Zero `else` reads downward, not sideways.
   **An `else` is a function you have not named yet** — it holds a second job, which is why it needed
   a second branch. Extract it and the `else` disappears on its own. Same for `elif`, once per arm.
   In a loop, `continue` is the early return.
3. **A condition is a named predicate.** `herd_is_listening` beats `nc -z 127.0.0.1 443`. The name
   holds the meaning; the command is detail.
4. **Verbs act, `ensure_` guards.** `install_vendor` works. `ensure_site_is_secured` makes something
   true or stops. The prefix tells the reader which.
5. **Poll the oracle, not the report.** Tools print `ERROR` and succeed. Read the port, the file, a
   separate check.
6. **Guard every flag value.** `--name` with no value leaves `shift 2` short and `$#` unchanged, so
   the loop never ends.
7. **Decide `set -e` in writing.** It is on, or the header says why not. Silence means you never
   decided.
8. **Comments carry discoveries, not narration.** `# herd start stops the data services` earns its
   line. `# ── Step 3 ──` above a line printing "Step 3" does not.
   **Needing one is evidence against the function.** A comment explaining *what* a body does means
   the name is wrong or the body is two jobs — fix that first, and the comment leaves on its own. A
   preamble longer than the function it introduces is the clearest form of the tell.
   **One sentence, when one sentence does it.** No `#` fence and no bold — the blank line already
   separated it, and the sentence that matters goes first. **Three lines, tapering** is what a block
   does once it has more than one sentence to say: each line shorter than the one above, so it
   narrows to a point and the eye finds its end without counting. Three is a shape, never a target.
   Padding one sentence into three to make it narrow is the waste `economy` names, wearing craft.
9. **Let it breathe.** Blank lines inside a body group steps into thoughts, so a function reads as
   three moves rather than eleven lines. A body with no blank line is held breath.
   **Breathing is space, not words** — the opposite mistake is filling the space that was doing the
   work. Same instinct as rule 8, one level up.
10. **`shellcheck` passes.** Not optional.
11. **One name, one meaning.** Every variable is global unless you say otherwise, so a name that
    means two things is a bug waiting for a refactor.
12. **A split moves its comments.** After extracting, the parent keeps only what the parts do not
    say. Facts left behind get read twice and edited once.
13. **Say why a defensive line survives.** A guard with no reason reads as redundant, and redundant
    is what gets simplified away.

## The Anti-Patterns

| Don't                          | Do                              | Why                                    |
| ------------------------------ | ------------------------------- | -------------------------------------- |
| 200 top-level lines            | `main` plus named steps         | No shape, no reading                   |
| `if … elif … else`             | Guard clauses, or a new function | Each branch is a job that wanted a name |
| A function you scroll to read  | The same steps, named            | Verbosity starts long before it hurts  |
| A raw test inside `if`         | A named predicate               | The name is the documentation          |
| Trusting a tool's message      | Poll what it claims             | Tools lie about themselves             |
| A banner above a labelled step | The label alone                 | The script says it twice               |
| Inlining a helper used once    | Naming it anyway                | The call-site reads as a sentence      |
| A comment that counts lines    | Say what the code does          | It rots the next time one moves        |
| A `#` fence around a comment   | The comment                     | The blank line already separated it    |
| A block that widens as it goes | Break the lines so it narrows   | A taper ends; a wall has to be scanned |
| One sentence padded to three  | The one sentence                | Narrow is a shape, not a target        |
| A body with no blank line     | Steps grouped into thoughts     | Held breath reads as one long move     |
| A name that hides what returns | `unit_targets_file`             | The call-site should read as what it gets |
| `echo` everywhere              | `step`, `note`, `fail`          | One voice, one place to change         |
| Bare `exit 1`                  | Documented exit codes           | The caller cannot branch on "it broke" |

## Portability

Write for the shell you have, and say so. These bite silently elsewhere:

| BSD, so macOS-only            | Portable instead                      |
| ----------------------------- | ------------------------------------- |
| `sed -i ''`                   | `awk` to a temp file, then `mv`       |
| `date -j -f`                  | Compare ISO dates as text — they sort |
| `md5`                         | `shasum`, or drop the hash            |
| `awk '{print $1}'` over paths | `--porcelain` output, or whole lines  |

Bash is the floor. Windows needs WSL or Git Bash — say so in the skill that ships the script.

## Real-World Examples

See [examples.md](examples.md).
