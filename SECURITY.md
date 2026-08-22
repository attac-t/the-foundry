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
merge whatever this repository says. Foundry runs under an identity without that
permission, and the provider is what refuses. A report that Foundry *could* merge
if its identity allowed it describes the design, not a fault in it.

Nor is a gate you can make pass by editing the gate. A run that rewrites its own
evaluator and reaches `complete` is [#66](https://github.com/attac-t/the-foundry/issues/66),
recorded and open.

## Versions

The newest release of each plugin. There is no long-term branch and nothing is
backported — `plugin.json` carries the version.
