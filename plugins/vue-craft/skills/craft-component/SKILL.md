---
name: craft-component
description: Vue SFC patterns. defineModel. Lazy loading. Types colocation.
---

# Skill: Craft Component

> "Components render. Composables think."

## The Standard

1. **`defineModel`**: Replace manual computed getter/setter for v-model.
2. **Lazy loading**: `defineAsyncComponent` for conditional or heavy components.
3. **Types colocation**: `Component.types.ts` lives with `Component.vue`.
4. **Naming**: `twn-{domain}-{component}/Twn{Domain}{Component}.vue`.

## The Anti-Patterns

| Don't                         | Do                      | Why              |
|-------------------------------|-------------------------|------------------|
| Manual v-model computed       | `defineModel<T>()`      | Vue 3.4+ pattern |
| Import all components eagerly | Lazy load conditional   | Bundle size      |
| Types in component file       | Separate `.types.ts`    | Reusability      |
| Generic names (`Form.vue`)    | Domain prefix           | Clarity          |

## Real-World Examples

See [examples.md](examples.md).
