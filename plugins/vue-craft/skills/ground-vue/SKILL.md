---
name: ground-vue
description: Vue 3 philosophy. Composition API. Reactivity as language. Invoke ONCE when entering Vue context.
---

# Skill: Vue Philosophy

> "Reactivity is the language. Composition is the grammar."

## The Standard

- **Composition Over Options**: Setup function is the constructor. No `this`. No lifecycle confusion.
- **Reactivity Primitives**: `ref` for values. `computed` for derivations. `watch` for side effects.
- **Don't Fight the Framework**: If it feels hard, you're doing it wrong.
- **Colocation**: What changes together lives together. Domain over technical layers.

## The Check

Stop and reconsider if:
- Using `ref` where `computed` belongs
- Using `watch` to compute derived values
- Fighting reactivity instead of embracing it
- Scattering related code across technical folders
- Writing imperative code in a reactive system

## The Protocol

Before writing Vue code:
1. **Check Reactivity**: Is this a value (`ref`) or derivation (`computed`)?
2. **Check Composition**: Can this logic be a composable?
3. **Check Colocation**: Does this belong with its domain?
4. **Only Then**: Write the code.

## The Ecosystem

Trust these conventions:
- Naming: `use{Feature}` for composables, `Twn{Domain}{Component}` for components
- Structure: `domains/{domain}/` over `components/`, `composables/`, `types/`
- State: Pinia setup stores with `defineStore(() => {})`
- Validation: Zod schemas with preprocessing
- Types: Inference over annotation. JSDoc for documentation.
