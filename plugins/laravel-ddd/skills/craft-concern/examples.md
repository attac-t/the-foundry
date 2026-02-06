# Concern: Examples

Thin concerns that wire behavior without owning it.

---

## Delegation to QueryBuilder

### ✅ Thin Scope Wiring
**Why?** Concern exposes. QueryBuilder owns.
```php
// Domain/Billing/Concerns/HasSubscription.php
trait HasSubscription
{
    public function activeSubscription(): HasOne
    {
        return
            $this
                ->hasOne(Subscription::class)
                ->where(column: 'status', operator: '=', value: SubscriptionStatus::Active);
    }

    public function scopeSubscribed(Builder $query): void
    {
        SubscriptionQueryBuilder::subscribed(query: $query);
    }
}
```

### ❌ Fat Scope — Query Logic in Trait
```php
trait HasSubscription
{
    public function scopeSubscribed(Builder $query): void
    {
        $query->whereHas('subscriptions', function ($q) {
            $q
                ->where('status', 'active')
                ->where('expires_at', '>', now())
                ->where('cancelled_at', null);
        });
    }
}
```

---

## Delegation to Collection

### ✅ Thin Collection Wiring
**Why?** Concern returns. Collection class pipelines.
```php
// Domain/Catalog/Concerns/HasProducts.php
trait HasProducts
{
    public function availableProducts(): ProductCollection
    {
        return $this->products->available();
    }

    public function featuredProducts(): ProductCollection
    {
        return $this->products->featured();
    }
}
```

### ❌ Fat Filter — Collection Logic in Trait
```php
trait HasProducts
{
    public function availableProducts(): Collection
    {
        return
            $this
                ->products
                    ->filter(fn (Product $p) => $p->is_active)
                    ->reject(fn (Product $p) => $p->stock <= 0)
                    ->sortByDesc('created_at');
    }
}
```

---

## Delegation to Action

### ✅ Thin Action Wiring
**Why?** Concern triggers. Action executes.
```php
// Domain/Fulfillment/Concerns/HasShipments.php
trait HasShipments
{
    public function ship(): Shipment
    {
        return app(CreateShipment::class)->execute(order: $this);
    }

    public function cancelShipment(): void
    {
        app(CancelShipment::class)->execute(order: $this);
    }
}
```

### ❌ Fat Method — Business Logic in Trait
```php
trait HasShipments
{
    public function ship(): Shipment
    {
        if ($this->status !== OrderStatus::Paid) {
            throw new UnpaidOrderException($this);
        }

        $shipment = Shipment::create([
            'order_id' => $this->id,
            'tracking_number' => Str::uuid(),
            'shipped_at' => now(),
        ]);

        $this->update(['status' => OrderStatus::Shipped]);
        ShipmentCreated::dispatch($shipment);

        return $shipment;
    }
}
```

---

## Boot Convention

### ✅ Model Event Hooks
**Why?** Laravel auto-discovers `boot{TraitName}`.
```php
// Support/Concerns/HasSlug.php
trait HasSlug
{
    protected static function bootHasSlug(): void
    {
        static::creating(fn ($model) =>
            $model->slug ??= Str::slug($model->{$model->slugSource()})
        );
    }

    abstract public function slugSource(): string;
}
```
