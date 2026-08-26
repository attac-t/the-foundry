---
name: decide-docs-site
description: When to keep docs in README vs build a dedicated docs site. Documentation strategy.
---

# Skill: Documentation Strategy

> "The README is a landing page, not a manual."

## The Decision

**README-only when:**
- Simple package with minimal configuration (`translatable`, `responsecache`)
- Fewer than 15 config keys
- 1-3 code examples cover all use cases
- Package has fewer than 3k stars (community doesn't demand depth)

**Docs site when:**
- Significant configuration surface area (`medialibrary`: 40+ config keys)
- Multiple usage patterns that need separate pages
- More than 3k stars (community expects depth)
- Advanced usage would bloat the README
- Upgrade guides span multiple major versions

## The Heuristic

Ask: *"Does the README scroll for more than 3 screens?"*

If yes, move depth to a docs site. Keep the README as a landing page + quick start.

## The Quick Test

| Ask                                            | Answer | Use         |
| ---------------------------------------------- | ------ | ----------- |
| Can you explain all features in 3 code blocks? | Yes    | README-only |
| More than 15 config keys?                      | Yes    | Docs site   |
| More than 3k GitHub stars?                     | Yes    | Docs site   |
| Multiple distinct usage patterns?              | Yes    | Docs site   |
| Does the README scroll past 3 screens?         | Yes    | Docs site   |
| Is upgrade documentation needed?               | Yes    | Docs site   |

**See also:** craft-docs (how to structure a docs site once you decide to build one), craft-readme (keeping the README tight as a landing page).

## Real-World Examples

See [examples.md](examples.md).
