# Shell

Shipped shell is `plugins/*/bin`, `lib` and `hooks`. Not `tests/` — those are bash on purpose and
hold no such rule.

**Invoke `kernel:craft-sh` before the first character.** Its standard is generative: the shape is
decided while writing. Applied afterwards, every rule in it is a rewrite of something already
load-bearing.

`bin/shell.sh` gates what an exit code can read. What it cannot, this is for.
