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

1. **One job per function.** If the name needs "and", split it. `ensure_database_answers` must not
   also copy an `.env`.
2. **Early return. Never `else`.** Guard, return, carry on. Zero `else` reads downward, not sideways.
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
9. **`shellcheck` passes.** Not optional.

## The Anti-Patterns

| Don't                          | Do                              | Why                                    |
| ------------------------------ | ------------------------------- | -------------------------------------- |
| 200 top-level lines            | `main` plus named steps         | No shape, no reading                   |
| `if … elif … else`             | Guard clauses                   | Nesting hides the path                 |
| A raw test inside `if`         | A named predicate               | The name is the documentation          |
| Trusting a tool's message      | Poll what it claims             | Tools lie about themselves             |
| A banner above a labelled step | The label alone                 | The script says it twice               |
| Inlining a helper used once    | Naming it anyway                | The call-site reads as a sentence      |
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
