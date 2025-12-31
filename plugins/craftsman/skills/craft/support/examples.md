# Support: Examples

Patterns for domain-agnostic code.

---

## Contracts

### ✅ Dependency Inversion
**Why?** Domain depends on Support contract, not vice versa.
```php
// Support/Contracts/Exportable.php
interface Exportable
{
    public function toExportArray(): array;
}

// Domain implements it
class Order extends Model implements Exportable { ... }
```

### ✅ Strategy Pattern
**Why?** Swappable implementations.
```php
// Support/Contracts/PaymentGateway.php
interface PaymentGateway
{
    public function charge(int $cents): PaymentResult;
}
```

---

## Traits

### ✅ Laravel Naming Convention
**Why?** `Has*`, `Interacts*`, `Can*` patterns.
```php
// Support/Concerns/HasUuid.php
trait HasUuid
{
    protected static function bootHasUuid(): void
    {
        static::creating(fn ($model) =>
            $model->uuid ??= Str::uuid()
        );
    }
}

// Support/Concerns/InteractsWithTimeRange.php
trait InteractsWithTimeRange { ... }
```

---

## Base Classes

### ✅ Abstract Foundation
**Why?** Shared behavior for domain to extend.
```php
// Support/Actions/Action.php
abstract class Action
{
    abstract public function execute(Data $data): mixed;
}
```

### ✅ Abstract QueryBuilder
**Why?** Common query methods.
```php
// Support/Database/QueryBuilder.php
abstract class QueryBuilder extends Builder
{
    public function whereActive(): self
    {
        return $this->where('is_active', true);
    }
}
```

---

## Integrations

### ✅ SDK Wrapper
**Why?** Isolate third-party from domain.
```php
// Support/Integrations/Slack/SlackClient.php
class SlackClient
{
    public function send(string $channel, string $message): void
    {
        // Guzzle/SDK calls here
    }
}
```
