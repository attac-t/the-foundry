---
name: ground-colocation
description: Colocation philosophy. What changes together lives together.
---

# Skill: Colocation

> "Proximity breeds understanding."

## The Standard

- **Domain over layer**: Group by feature, not by technical layer. `domains/invoices/` not `components/invoices/`, `stores/invoices/`, `types/invoices/`.
- **Change together, live together**: If editing one file always means editing another, they belong in the same directory.
- **Boundaries are explicit**: A domain is a self-contained unit. It owns its types, composables, components, and tests.

## The Check

Ask yourself:
- When I change this feature, how many directories do I touch?
- Can I delete this domain folder and remove the feature completely?
- Would a new developer find related code without searching?

## Real-World Examples

See [examples.md](examples.md).
