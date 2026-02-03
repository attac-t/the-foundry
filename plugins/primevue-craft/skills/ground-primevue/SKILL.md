# Skill: PrimeVue Philosophy

> "Wrappers create consistency. Raw components create chaos."

## The Standard

- **Wrap for consistency**: Same validation, same slots, same behavior across all forms
- **defineModel for state**: Modern Vue 3 two-way binding, one per state
- **Slot forwarding**: Pass all parent slots to wrapped component
- **Three-state validation**: true (valid), false (invalid), null (neutral)
- **Unique field names**: `uniqueId()` for HTML label/input association

## The Architecture

```
Component Wrapper (TwnDataTable, TwnDialog)
├── defineModel for each two-way state
├── Props for configuration
├── Slot forwarding loop
└── PrimeVue component with PT overrides
```

## The Anti-Patterns

| Don't                              | Do                                       |
|------------------------------------|------------------------------------------|
| Use raw PrimeVue in domain code    | Use project wrapper (Twn prefix)         |
| Duplicate validation styling       | Standardize in InputLabelMessageGroup    |
| Manual v-model for multiple states | Separate defineModel per state           |
| Hardcode field names               | Generate with uniqueId()                 |
| Override PT inline                 | Use usePrimeVuePtMerge() composable      |

## The Check

Ask yourself:
- Does this wrapper add consistency?
- Is slot forwarding complete?
- Are all two-way bindings using defineModel?
- Is validation state handled uniformly?
