# Skill: Inertia Philosophy

> "SPA behavior, MPA simplicity."

## The Standard

- **Form as source**: `useForm` owns truth. Sync reactive state to it, not around it.
- **Notify lifecycle**: `init → processing → success/error`. Same toast ID for update-in-place.
- **Dual variants**: Inertia for page transitions. API for chaining operations.
- **Router owns navigation**: `router.get/post/delete`. Never manual fetch for nav.
- **Trust defaults**: No explicit `preserveState/preserveScroll` unless needed.

## The Anti-Patterns

| Don't                              | Do                                       |
|------------------------------------|------------------------------------------|
| Create parallel state to form      | Sync state to form via `useFormAgent`    |
| Show multiple toasts per operation | Reuse same toast ID                      |
| Use Inertia when chaining ops      | Use API variant, then reload             |
| `fetch()` for navigation           | `router.visit()` or `router.get()`       |
| Hardcode `preserveState: true`     | Rely on Inertia defaults                 |

## The Check

Ask yourself:
- Does the form own truth?
- Is there one toast per operation (updating in place)?
- Am I using the right variant (Inertia vs API)?
- Is navigation going through the router?
