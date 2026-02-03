# PrimeVue Craft

PrimeVue component patterns for Vue 3.

This plugin knows **how to wrap PrimeVue**. The kernel knows how to think. `vue-craft` knows how to structure Vue. This knows how to build consistent UI components.

---

## Philosophy

Wrappers over raw components. Consistency over flexibility. Composition over configuration.

Every pattern exists because raw PrimeVue needed guardrails. Every decision has a heuristic.

---

## Grounding

When you enter PrimeVue context, activate `ground-primevue` — the wrapper philosophy:

```
Wrap for consistency      Same validation, same slots, same behavior
defineModel for state     Modern Vue 3 two-way binding
Slot forwarding           Pass all parent slots to wrapped component
Three-state validation    true (valid), false (invalid), null (neutral)
```

---

## What You Get

```
TwnDataTable          Multi-state defineModel, column presets, lazy empty
TwnDialog             Minimal wrapper with header/default/footer slots
TwnSlideOver          Responsive Drawer (right on desktop, bottom on mobile)
InputSelectGroup      Form group with add button pattern
InputAutocompleteGroup Dual search fields (label + searchableText)
InputTreeSelectGroup  Memoized selection with consolidation
TwnPanel              Lazy content, clickable header, badge support
```

---

## Skills

10 skills. Three types.

```
ground-*     Philosophy and mindset (1 skill)
craft-*      How to build (8 skills)
decide-*     When to use what (1 skill)
```

### Highlights

```
craft-data-table         Column presets, slot forwarding
craft-input-group        Form group stack architecture
craft-autocomplete-group Dual search with workarounds
craft-tree-select-group  Memoization for large hierarchies
decide-wrapper-vs-raw    When to wrap vs use directly
```

Run `/skills primevue-craft` to see all.

---

## Installation

Requires `kernel` for cognitive patterns and `vue-craft` for Vue fundamentals.

```
/plugin install kernel@the-foundry
/plugin install vue-craft@the-foundry
/plugin install primevue-craft@the-foundry
```

---

## Recommended Packages

The skills assume these are installed:

```
primevue 4.x         Component library
lodash-es            uniqueId for field names
```

---

## Documentation

- [PrimeVue Official Docs](https://primevue.org/)
- [PrimeVue Vue 3 Components](https://primevue.org/installation/)

---

## Related

- `vue-craft` — Vue 3 Composition API patterns (required)
- `vue-inertia` — Inertia.js patterns

---

## License

MIT
