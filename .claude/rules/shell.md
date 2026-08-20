# Shell

Shipped shell is `plugins/*/bin`, `lib` and `hooks`. Not `tests/` — those are bash on purpose and
hold no such rule.

**Invoke `kernel:craft-sh` before editing one.** The standard lives there. This exists because nobody
goes looking for a standard while already writing, and the same corrections keep arriving in review
instead.

`bin/shell.sh` gates an `else` and a body past forty lines. It cannot gate the one that recurs most —
a preamble longer than the function it introduces — because a comment is only wrong when it says what
the code already says, and no exit code reads that. So that one is a reading, every time.
