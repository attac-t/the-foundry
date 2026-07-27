---
name: craft-command
description: How to craft a Slash Command trigger.
---

# Skill: Craft Command

> "Thin commands. Fat skills."

## The Philosophy

Commands are **triggers**, not logic containers. Judgment belongs in a skill; the
command names the skill and passes the arguments.

## The Spec

**Read first**: https://code.claude.com/docs/en/slash-commands

Commands and skills have merged. A file at `commands/deploy.md` and a skill at
`skills/deploy/SKILL.md` both produce `/deploy`.

## The Pattern

A command body is a **prompt**. There is no path-like invocation syntax — no
`/skills/name`, no `/agents/name`. Write the instruction and name the skill.

```markdown
---
description: One-line purpose.
argument-hint: "<what the user provides>"
---

Invoke the `plugin:skill-name` skill on: $ARGUMENTS
```

Quote `argument-hint` always. A value containing `: ` parses as a nested mapping
and silently drops the whole frontmatter block; a bare `[foo]` becomes a list.

## Frontmatter Reference

| Field                      | Purpose                                    |
|----------------------------|--------------------------------------------|
| `description`              | Brief purpose (shown in autocomplete)      |
| `argument-hint`            | Expected arguments. Quote it.              |
| `allowed-tools`            | Pre-approve tools for this turn            |
| `disallowed-tools`         | Remove tools while active                  |
| `model`                    | Override the model for this command        |
| `disable-model-invocation` | `true` = only the user can trigger it      |
| `user-invocable`           | `false` = hide from the `/` menu           |

## Arguments

- `$ARGUMENTS` — every argument as one string
- `$0`, `$1`, … — positional access (`$ARGUMENTS[N]` longhand)
- `arguments: [issue, branch]` in frontmatter enables `$issue`, `$branch`

## See Also

- `examples.md` — patterns and anti-patterns
