# Cache Store: Examples

---

## Architecture

```
Domain Store (useUsersStore)
├── Loading state, API calls, selectors
└── Uses cache store internally
        ↓
Cache Store (useUsersCacheStore)
└── LRU storage only: get, set, clear
```

---

## Cache Store (Factory)

```typescript
export const useUsersCacheStore = createLRUCacheStore<User>(
  CACHE_STORE_KEYS.USERS,
  { max: 200 }
)
```

---

## Domain Store

```typescript
export const useUsersStore = defineStore('users', () => {
  const cacheStore = useUsersCacheStore()
  const isLoading = ref(false)
  const isLoaded = ref(false)

  const fetch = async (): Promise<User[]> => {
    if (isLoaded.value) return cacheStore.getAll()
    isLoading.value = true
    const response = await api.index()
    cacheStore.setMany(response.data.value?.data ?? [])
    isLoaded.value = true
    isLoading.value = false
    return cacheStore.getAll()
  }

  const users = computed(() => isLoaded.value ? cacheStore.getAll() : [])

  return { isLoading, isLoaded, users, fetch }
})
```

---

## ensureInCache

```typescript
const ensureUserInCache = async (userId: string): Promise<User | undefined> => {
  const cached = cacheStore.get(userId)
  if (cached) return cached

  const response = await api.show({ id: userId })
  if (response.data.value) cacheStore.set(response.data.value)
  return response.data.value
}
```
