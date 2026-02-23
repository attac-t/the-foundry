---
name: ground-playbook
description: Core philosophy. DX is the north star for every package decision.
---

# Skill: The Playbook

> "Every great package was born from a real problem."

## The Standard

- **DX Is The North Star**: Every decision is evaluated through one lens: how does the developer experience this? Not how clever. How it *feels*.
- **Zero-Config Defaults**: A package works on first run. Config publishing is optional. Auto-discovery handles the rest.
- **Progressive Disclosure**: Simple things simple, complex things possible. Trait (80%), config (15%), provider (4%), contract (1%).
- **One Polished Feature**: A small package with one brilliant feature beats a large package covering every edge case. Scope is a discipline.
- **Born From Real Problems**: Taylor built Cashier from Forge billing. Nuno built Pest because PHPUnit felt heavy. Filament grew from needing a better admin panel. Solve it in production first.
- **Convention Over Configuration**: Method names read like English. Traits integrate where developers think -- on models. The API should feel inevitable, not learned.
- **Errors That Teach**: Every exception tells the developer what went wrong AND what's valid. One exception class per failure mode.
- **Beauty Matters**: Developer tools should feel good to use. Beautiful output is a competitive advantage, not vanity.
- **Extensibility Over Protection**: Give developers seams. `protected` over `private`. Events at key points. Fewer feature requests, better DX.

## The Check

Ask yourself:
- Is the API obvious in 30 seconds?
- Does it work with zero configuration?
- Can a developer extend without forking?
- Does it solve a problem you've hit in production?

## Real-World Examples

See [examples.md](examples.md).
