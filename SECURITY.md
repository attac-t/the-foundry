# Security

**Report privately: [open a draft advisory](https://github.com/attac-t/the-foundry/security/advisories/new).**

Never as an issue. Issues are public the moment you press the button.

You will get an answer. If a week passes with none, chase it in the advisory
thread — it is private and it stays private.

## What is worth reporting

These plugins ship shell that runs on a contributor's machine, inside their
repository, with their credentials. So:

- a hook or gate that runs input it was handed
- a path that escapes the directory it was given
- anything that reads a token, a key, or `~/.claude/settings.json` and sends it anywhere
- a skill whose words steer an agent into doing one of the above

## What is not

**Merging is not a boundary floor can hold, and it says so.** `.foundry/practice`
grants grading and delivering, never merging — anything that can run `gh` can
merge whatever this repository says. A report that floor did not stop a merge
describes the design, not a fault in it.

**This used to say the identity lacks that permission and the provider refuses.
It does not.** Measured 2026-08-25: the identity `gh` holds on the machine doing
this work has `admin` here, and over a hundred pull requests are merged under it.
The old sentence dismissed a true report as hypothetical.

Whether the provider *should* refuse is about how this repository is configured,
and it is open as [#156](https://github.com/attac-t/the-foundry/issues/156).

**A gate you can make pass by editing the gate used to be here too, pointing at
[#66](https://github.com/attac-t/the-foundry/issues/66) as recorded and open.
#66 closed on 2026-08-23, and so did the hole.** A run that changes a file its own
gates run is graded with the base's copy of that file, and the run records which
ones in `substitutions`.

**One form of it is still open, and it is narrower.** The restore follows a gate
command's file closure by literal path. A gate that reaches a file through a
variable — as `bin/gates.sh` reaches each plugin's suite — is not followed, so a
run can rewrite that file and be graded by its own copy.

That is [#341](https://github.com/attac-t/the-foundry/issues/341), open, with the
cost of closing it measured on the issue. A report of the direct form is already
caught; a report of this one is worth sending.

## Versions

The newest release of each plugin. There is no long-term branch and nothing is
backported — `plugin.json` carries the version.
