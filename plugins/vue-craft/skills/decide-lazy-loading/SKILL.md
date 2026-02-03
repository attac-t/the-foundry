---
name: decide-lazy-loading
description: Conditional rendering? Lazy load it.
---

# Decide: Lazy Loading

> "Don't load what won't render."

## The Heuristic

| Lazy Load When                     | Eager Load When  |
|------------------------------------|------------------|
| Conditionally rendered (`v-if`)    | Always rendered  |
| Heavy component (complex tree)     | Simple atom      |
| Below the fold                     | Above the fold   |
| Rarely used (dialogs, slide-overs) | Core UI elements |

## Quick Test

**Ask:** "Will this component render on initial page load?"

- **No** → `defineAsyncComponent`
- **Yes** → Direct import

## The Anti-Pattern

**Lazy everything**: Adds loading states to simple components. More code. Worse UX.

## Real-World Examples

See [examples.md](examples.md).
