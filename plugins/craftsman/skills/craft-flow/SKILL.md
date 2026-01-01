---
name: craft-flow
trigger: flowchart, lifecycle, process diagram, system flow
description: Generate elegant ASCII flowcharts.
---

# Skill: Craft Flow

> "Show the river, not every droplet."

## The Principles

- **Vertical** — Top to bottom only
- **Stages in CAPS** — Clear phase boundaries
- **Minimal chrome** — Characters are spice, not the meal

## The Format

```
STAGE NAME
    │
    ├── step           description
    └── step           description
    │
    ▼
NEXT STAGE
```

## The Characters

| Char | Usage |
|------|-------|
| `│` | Vertical flow |
| `├──` | Branch (more follows) |
| `└──` | Branch (last) |
| `▼` | Stage transition |
| `←` | Inline annotation |

## The Rules

1. Stages: ALL CAPS
2. Steps: lowercase, indented
3. End with one-line summary

## See Also

- `examples.md` — full examples
