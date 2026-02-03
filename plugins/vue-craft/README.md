# Vue Craft

Opinionated Vue 3 Composition API patterns.

This plugin knows **how to structure Vue code**. The kernel knows how to think. This knows how to build reactive interfaces.

---

## Philosophy

Composition over Options. Colocation over convention. Reactivity as language.

Every pattern exists because inline code became unmanageable. Every decision has a heuristic.

---

## Grounding

When you enter Vue context, activate `ground-vue` — the Vue philosophy:

```
Composition API       Setup function is your constructor
Colocation            What changes together lives together
Reactivity primitives ref for state, computed for derivation, watch for effects
Don't fight it        If it feels hard, you're doing it wrong
```

---

## What You Get

```
Domain structure      Self-contained folders that delete cleanly
Typed composables     MaybeRefOrGetter inputs, object returns
Zod validation        Cross-component registry via provide/inject
Pinia stores          Setup syntax with consume pattern
Clean components      defineModel, lazy loading, thin wrappers
```

---

## Skills

34 skills. Three types.

```
ground-*     Philosophy and mindset (3 skills)
craft-*      How to build (25 skills)
decide-*     When to use what (6 skills)
```

### Highlights

```
craft-composable           MaybeRefOrGetter inputs, named returns
craft-zod-registry         Aggregate validation across component tree
craft-cache-store          Two-store architecture (domain + cache)
craft-orchestration-composable  Multi-step flows with detection
decide-store-vs-composable Survives unmount? Store.
decide-util-vs-composable  Vue imports? Composable.
```

Run `/skills vue-craft` to see all.

---

## Installation

Requires `kernel` for cognitive patterns.

```
/plugin install kernel@the-foundry
/plugin install vue-craft@the-foundry
```

---

## Recommended Packages

The skills assume these are available:

```
vue 3.4+        Composition API, defineModel
pinia           State management
zod             Schema validation
vitest          Testing
```

---

## Related

- `vue-inertia` — Inertia.js patterns (form agents, page operations)
- `primevue-craft` — PrimeVue component patterns (planned)

---

## License

MIT
