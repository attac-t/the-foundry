# Shell

Shipped shell is `plugins/*/bin`, `lib` and `hooks`. Not `tests/` — those are bash on purpose and
hold no such rule.

**Invoke `kernel:craft-sh` before the first character.** Its standard is generative: `main` reading as
the whole story, one job to a function, an `else` extracted before it exists. Those are decisions
taken while writing. Taken afterwards, each is a rewrite of something already load-bearing.

`bin/shell.sh` gates an `else` and a body past forty lines, and both are the after. The one that
matters most it cannot gate at all: a comment saying what the code already says means the name is
wrong, and no exit code reads a name.
