---
name: craft-domain-structure
description: Domain directory layout. Atomic design with colocation.
---

# Skill: Craft Domain Structure

> "Structure reveals intent."

## The Standard

1. **Domain root**: `domains/{domain-name}/` — kebab-case, plural noun.
2. **Components**: Atomic design hierarchy (`atoms/`, `molecules/`, `organisms/`).
3. **Composables**: `composables/use-{feature}/` — one directory per composable.
4. **Types**: Subdirectories by purpose (`consts/`, `models/`, `requests/`, `responses/`).
5. **Store**: `store/use{Domain}Store.ts` — Pinia setup store.
6. **Validations**: `validations/ui/` — Zod schemas for forms.

## The Anti-Patterns

| Don't                          | Do                                   | Why                              |
|--------------------------------|--------------------------------------|----------------------------------|
| `components/InvoiceForm.vue`   | `components/organisms/invoice-form/` | Atomic design requires hierarchy |
| `types/Invoice.ts`             | `types/models/Invoice.types.ts`      | Subdirectories by purpose        |
| `useInvoice.ts` at root        | `composables/use-invoice/`           | Colocation with types            |
| `validations.ts`               | `validations/ui/{schema}.schema.ts`  | Separate UI from API validation  |

## Real-World Examples

See [examples.md](examples.md).
