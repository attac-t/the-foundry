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
| [decide](templates/decide.md)                       | X vs Y decision     | Heuristic + Quick Test + examples.md   |
| [craft](templates/craft.md)                         | How to build X      | Standard + Anti-Patterns + examples.md |
| [ground-protocol](templates/ground-protocol.md)     | Step-by-step ritual | When + Protocol + Output               |
| [ground-philosophy](templates/ground-philosophy.md) | Mindset/standards   | Standard + Check + examples.md         |

## The Structure

```
plugins/{plugin-name}/skills/{skill-name}/
├── SKILL.md        # The skill definition
└── examples.md     # Concrete code examples (if needed)
```

**Naming**: Flat directories with prefix. `ground-vue/` not `ground/vue/`.

**Path**: Skills live at `plugins/{plugin}/skills/`, not `.claude-plugin/skills/`.

**plugin.json**: Uses `"skills": "./skills/"` (resolved relative to plugin root).

## Official Spec

Use `claude-code-guide` agent to query Claude Code skill documentation.

## Registration (CRITICAL)

> [!IMPORTANT]
> **Sub-agents do not inherit skills.**

After creating `SKILL.md`, add `{skill_name}` to `skills:` in:
- `agents/architect.md`
- Any other agents that need the skill

**Unregistered skills do not exist.**
