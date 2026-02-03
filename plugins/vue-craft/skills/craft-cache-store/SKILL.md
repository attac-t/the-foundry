---
name: craft-cache-store
description: Two-store architecture. Domain + cache separation. LRU storage.
---

# Skill: Craft Cache Store

> "Logic in one store. Storage in another."

## The Standard

1. **Domain store**: Loading state, API calls, computed selectors, business logic.
2. **Cache store**: Pure LRU storage. No domain logic. Just `get`, `set`, `clear`.
3. **Factory creation**: `createLRUCacheStore<T>('name', { max })` — consistent cache stores.
4. **`ensureInCache()`**: Lazy load pattern. Check cache first, fetch if missing.

## The Anti-Patterns

| Don't                              | Do                       | Why                   |
|------------------------------------|--------------------------|-----------------------|
| Mix fetch logic in cache store     | Domain store handles API | Single responsibility |
| Duplicate cache implementations    | Factory pattern          | DRY                   |
| Forget `triggerRef` after mutation | Factory handles it       | Reactivity            |
| Unbounded cache growth             | LRU with max size        | Memory safety         |

## Real-World Examples

See [examples.md](examples.md).
