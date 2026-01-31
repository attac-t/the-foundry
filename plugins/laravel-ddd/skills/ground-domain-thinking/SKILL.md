---
name: ground-domain-thinking
description: Domain thinking. Code mirrors business reality.
---

# Skill: Domain Thinking

> "Humans think in categories. Our code should be a reflection of that."

## The Standard

- **Business Language**: Name things as the client names them. Not technical jargon.
- **Group by Domain**: `Invoicing/`, `Shipping/`, not `Models/`, `Controllers/`.
- **Translate, Don't Dictate**: Your job is translator between business and code.

## The Check

Ask yourself:
- Would a domain expert recognize this folder structure?
- Can I explain this class name to a non-developer?
- Does the code reflect how the business actually works?

## The Protocol

1. **Listen**: Spend time with domain experts. Hear their language.
2. **Map**: Create glossary of domain terms. Use them consistently.
3. **Structure**: Group code by business domain, not technical layer.
4. **Evolve**: Domains change. Refactor structure as understanding deepens.

## Real-World Examples

See [examples.md](examples.md).
