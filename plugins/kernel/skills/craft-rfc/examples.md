# RFC: Examples

Template and real-world patterns.

---

## Template

```markdown
# RFC-NNN: Title

**Status:** Draft | Accepted | Implemented | Superseded
**Author:** [name]
**Date:** YYYY-MM-DD

---

## Abstract

One paragraph. What is this and why does it matter?

---

## Problem

What problem are we solving? What constraints exist?
What happens if we do nothing?

---

## Solution

### Overview

High-level approach. How does it work conceptually?

### API

```php
// How do you use it?
$thing->doSomething();
```

### Implementation

Key technical details. Data structures, algorithms, storage.

---

## Open Questions

1. **Question** — Context for why it's unresolved.
2. **Question** — Options being considered.

---

## References

- [Prior Art](https://example.com) — Why it's relevant
- [Related RFC](./RFC-Related.md) — Connection
```

---

## Real-World Example

```markdown
# RFC-001: Bi-Temporal Versioning

**Status:** Accepted
**Author:** Engineering
**Date:** 2025-02-03

---

## Abstract

A Laravel package for versioning aggregate roots with nested relations,
using content-addressable Merkle trees for storage efficiency and
bi-temporal queries for historical accuracy.

---

## Problem

We need to version aggregates (Templates, Menus) where:

1. **Historical accuracy** — Certificates issued in 2023 must render in 2028
2. **Nested atomicity** — Template → Items → Placeholders as one unit
3. **Storage efficiency** — Thousands of revisions shouldn't bloat DB
4. **Safety** — Cannot accidentally pin uncommitted state

Existing solutions track field-level changes but don't solve aggregate snapshots.

---

## Solution

### Overview

- Merkle tree captures entire aggregate state
- Content-addressable storage deduplicates unchanged nodes
- Bi-temporal columns track valid time vs recorded time
- `#[Versioned]` attribute declares which relations to include

### API

```php
$template->revise('Initial design');
$hash = $template->snapshot();
$original = Template::fromSnapshot($hash);
```

### Implementation

Three tables: `revisions`, `snapshot_manifests`, `snapshot_values`.
Structural sharing via content-addressed hashes.

```
┌─────────────────────────────────────────────────────────────────┐
│                        snapshot_values                          │
├─────────────────────────────────────────────────────────────────┤
│  hash_a → {name: "Certificate", paper_size: "A4"}               │
│  hash_b → {type: "text", content: "Hello"}                      │
└─────────────────────────────────────────────────────────────────┘
                              ▲
                              │
┌─────────────────────────────────────────────────────────────────┐
│                          revisions                              │
├─────────────────────────────────────────────────────────────────┤
│  branch: main                                                   │
│  manifest_hash ────────────────────────────────────────────────▶│
│  valid_from, valid_to, recorded_at                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Open Questions

1. **Pruning strategy** — How to garbage collect orphaned nodes?
2. **Chunk size** — Optimal size for ProllyTree? (32-64 items?)

---

## References

- [Merkle Trees](https://en.wikipedia.org/wiki/Merkle_tree)
- [Bi-Temporal Modeling](https://martinfowler.com/articles/bitemporal-history.html)
- [Dolt](https://www.dolthub.com/) — Git-for-data using ProllyTrees
```

---

## Minimal RFC

For smaller features, trim to essentials:

```markdown
# RFC-002: Rate Limiting Middleware

**Status:** Draft
**Date:** 2025-02-04

## Problem

API endpoints have no rate limiting. Vulnerable to abuse.

## Solution

Use Laravel's built-in `ThrottleRequests` middleware with Redis backend.
Configure per-route limits via route groups.

## Open Questions

1. **Limits** — What thresholds per endpoint type?
```
