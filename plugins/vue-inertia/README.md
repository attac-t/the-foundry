# Vue Inertia

Inertia.js patterns for Vue 3.

This plugin knows **how to wire Inertia**. The kernel knows how to think. `vue-craft` knows how to structure Vue. This knows how to make them talk.

---

## Philosophy

SPA behavior, MPA simplicity. Forms sync state. Operations notify. Router navigates.

Every pattern exists because Inertia's defaults weren't enough. Every decision has a heuristic.

---

## Grounding

When you enter Inertia context, activate `ground-inertia` — the Inertia philosophy:

```
Form as source         useForm owns truth. Sync state to it.
Notify lifecycle       init → processing → success/error. Same toast ID.
Dual variants          Inertia for page transitions. API for chaining.
Router owns nav        router.get/post/delete. No manual fetching.
```

---

## What You Get

```
useFormAgent         Reactive state synced to Inertia form
useEntityNotification Toast lifecycle for CRUD ops
Operation composables Create/Update/Delete with dual variants
Router navigation    get/post/delete/reload patterns
```

---

## Skills

7 skills. Three types.

```
ground-*     Philosophy and mindset (1 skill)
craft-*      How to build (5 skills)
decide-*     When to use what (1 skill)
```

### Highlights

```
craft-form-agent             State + form sync with slug stripping
craft-entity-notification    Toast ID reuse for update-in-place
craft-operation-composable   Inertia vs API variants
decide-inertia-vs-api        When page reload vs Promise chain
```

Run `/skills vue-inertia` to see all.

---

## Installation

Requires `kernel` for cognitive patterns and `vue-craft` for Vue fundamentals.

```
/plugin install kernel@the-foundry
/plugin install vue-craft@the-foundry
/plugin install vue-inertia@the-foundry
```

---

## Recommended Packages

The skills assume these are installed:

```
@inertiajs/vue3      Inertia adapter
lodash-es            Deep merge for form defaults
```

---

## Related

- `vue-craft` — Vue 3 Composition API patterns (required)
- `primevue-craft` — PrimeVue component patterns (planned)

---

## License

MIT
