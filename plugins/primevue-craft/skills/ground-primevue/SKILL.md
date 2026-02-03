# Skill: PrimeVue Philosophy

> "Wrappers create consistency. Raw components create chaos."

## CRITICAL: Always Check Docs

PrimeVue evolves rapidly. Before implementing:

1. **Fetch latest docs**: https://primevue.org/
2. **Verify API**: Props, events, slots may have changed
3. **Check PT system**: Pass-through styling evolves between versions

Do not assume. Verify.

## The Standard

- **Wrap for consistency**: Same validation, same slots, same behavior
- **defineModel for state**: One defineModel per two-way binding
- **Slot forwarding**: Pass all parent slots to wrapped component
- **Three-state validation**: true (valid), false (invalid), null (neutral)
- **Unique field names**: `uniqueId()` for label/input association

## The Anti-Patterns

| Don't                              | Do                                        |
|------------------------------------|-------------------------------------------|
| Use raw PrimeVue in domain code    | Use project wrapper                       |
| Duplicate validation styling       | Standardize in InputLabelMessageGroup     |
| Manual v-model for multiple states | Separate defineModel per state            |
| Hardcode field names               | Generate with uniqueId()                  |
| Assume API unchanged               | Check docs for current version            |

## The Check

- Does this wrapper add consistency?
- Is slot forwarding complete?
- Did I verify the current PrimeVue API?

## Real-World Examples

See [examples.md](examples.md).
