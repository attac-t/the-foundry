# Extensibility: Examples

When and why to make code flexible. For full implementation patterns, see craft-extension-point.

---

## The Decision Framework

Every extension point answers one question: *"Can a consumer customize this without forking?"*

### Match Mechanism to Scale

| Scale              | Pattern           | Example                                     |
| ------------------ | ----------------- | ------------------------------------------- |
| Simple swap        | Config binding    | Spatie model customization                  |
| Single behavior    | Static callback   | `Sanctum::getAccessTokenFromRequestUsing()` |
| Runtime methods    | Macroable         | `Collection::macro()`                       |
| Multi-driver       | Manager/Driver    | Scout, Socialite, Pennant                   |
| Framework-agnostic | Adapter/Interface | Flysystem, EventSauce                       |
| Platform hosting   | Plugin system     | Filament panels                             |
| Decoupled reaction | Events            | Webhook handling, state changes             |

Start with the lightest mechanism that solves the problem. Escalate only when needed.

---

## The Seam Principle

Every meaningful behavior needs a seam — a point where consumers can intercept, replace, or extend.

### Where Seams Come From

```php
// Config seam — swap a class
'models' => ['role' => App\Models\Role::class]

// Callback seam — customize a behavior
Cashier::formatCurrencyUsing(fn ($amount, $currency) => /* ... */);

// Interface seam — implement a contract
class DropboxAdapter implements FilesystemAdapter { /* ... */ }

// Event seam — react without coupling
RoleAttachedEvent::dispatch($model, $rolesOrIds);
```

Each seam type has a different cost and flexibility trade-off. Config is cheapest. Interfaces are most powerful. Events are most decoupled.

---

## Protected Over Private

```php
// Closed — consumer cannot customize
private function resolveNotificationChannel(): string { /* ... */ }

// Open — consumer can override in subclass
protected function resolveNotificationChannel(): string { /* ... */ }
```

Every `private` method is a feature request waiting to happen. Default to `protected`. Use `private` only for true implementation details that must never change.

---

## The Escalation Pattern

Real packages evolve their extension points:

1. **v1**: Config-driven binding (simple swap)
2. **v2**: Add static callbacks for fine-grained customization
3. **v3**: Introduce Manager/Driver when multiple implementations emerge
4. **v4**: Ship a plugin system when third parties build on top

Scout started with a single driver. Now it has a full EngineManager with `extend()`. Pennant started config-driven. Now it supports custom feature stores. Don't over-engineer day one — but design so you can escalate.
