---
name: craft-skill
description: How to craft an atomic skill. Includes templates and registration.
---

# Skill: Craft Skill

> "Atomic units of intelligence."

## The Principles

- **Atomicity**: One concept per file. If it does two things, split it.
- **Brevity**: Less is more. No verbose explanations.
- **Expertise**: Write *how an expert thinks*, not checklists.

## Choose a Template

| Template                                            | Use When            | Pattern                                |
|-----------------------------------------------------|---------------------|----------------------------------------|
| [decide](templates/decide.md)                       | X vs Y decision     | Heuristic + Quick Test → examples.md   |
| [craft](templates/craft.md)                         | How to build X      | Standard + Anti-Patterns → examples.md |
| [ground-protocol](templates/ground-protocol.md)     | Step-by-step ritual | When + Protocol + Output               |
| [ground-philosophy](templates/ground-philosophy.md) | Mindset/standards   | Standard + Check → examples.md         |

## The Structure

```
skills/{category}/{name}/
├── SKILL.md        # The skill definition
└── examples.md     # Concrete code examples (if needed)
```

## Official Spec

Use `claude-code-guide` agent to query Claude Code skill documentation.

## Registration (CRITICAL)

> [!IMPORTANT]
> **Sub-agents do not inherit skills.**

After creating `SKILL.md`, add `{skill_name}` to `skills:` in:
- `agents/architect.md`
- `agents/reviewer.md`

**Unregistered skills do not exist.**
