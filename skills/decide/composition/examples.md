# Composition: Examples

Real-world examples of the Trait+Interface vs Abstract Class decision.

---

## Laravel Framework

### ✅ Trait: `SoftDeletes`
**Why?** A model **has** soft delete capability. Any model can mix this in.
```php
class Order extends Model { use SoftDeletes; }
class User extends Model { use SoftDeletes; }
```

### ✅ Trait: `Authenticatable`
**Why?** User **has** auth capability. Multiple unrelated models might need it.
```php
class User extends Model { use Authenticatable, Authorizable; }
```

### ✅ Abstract: `Model`
**Why?** All Eloquent models **are** Models. Clear IS-A relationship.
```php
abstract class Model { public function save() { /* shared */ } }
```

---

## Spatie Packages

### ✅ Trait: `InteractsWithMedia`
**Why?** Models **have** media interactions. Crosses hierarchies.
```php
class Product extends Model { use InteractsWithMedia; }
class BlogPost extends Model { use InteractsWithMedia; }
```

### ✅ Trait: `HasRoles`
**Why?** Roles are a capability, not an identity.
```php
class User extends Model { use HasRoles; }
class Team extends Model { use HasRoles; } // Teams too
```

---

## Production Patterns

### ✅ Trait + Interface: Cross-cutting Behavior
```php
interface HasTimeRange { public function isActive(): bool; }
trait InteractsWithTimeRange { /* implementation */ }

class Campaign extends Model implements HasTimeRange { use InteractsWithTimeRange; }
class Subscription extends Model implements HasTimeRange { use InteractsWithTimeRange; }
```

### ✅ Abstract: Template Method Pattern
```php
abstract class AbstractReport {
    abstract protected function query(): Builder;
    public function generate(): Collection { return $this->query()->get(); }
}
class SalesReport extends AbstractReport { /* ... */ }
```


