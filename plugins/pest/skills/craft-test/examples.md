# Pest v3 Examples

Real-world testing patterns. Copy, adapt, use.

---

## Factory Patterns

### Basic Factory with State

```php
describe('Order states', function () {
    it('creates pending order by default', function () {
        $order = Order::factory()->create();

        expect($order->status)->toBe(OrderStatus::Pending);
    });

    it('creates confirmed order with state', function () {
        $order = Order::factory()
            ->confirmed()
            ->create();

        expect($order)
            ->status->toBe(OrderStatus::Confirmed)
            ->confirmed_at->not->toBeNull();
    });
});
```

### Factory with Relationships

```php
describe('Order with items', function () {
    it('creates order with line items', function () {
        $order = Order::factory()
            ->has(OrderItem::factory()->count(3), 'items')
            ->create();

        expect($order->items)->toHaveCount(3);
    });

    it('creates order for specific customer', function () {
        $customer = Customer::factory()->create();

        $order = Order::factory()
            ->for($customer)
            ->create();

        expect($order->customer_id)->toBe($customer->id);
    });
});
```

### Sequence Pattern

```php
it('creates orders with sequential statuses', function () {
    $orders = Order::factory()
        ->count(3)
        ->sequence(
            ['status' => OrderStatus::Pending],
            ['status' => OrderStatus::Confirmed],
            ['status' => OrderStatus::Shipped],
        )
        ->create();

    expect($orders[0]->status)->toBe(OrderStatus::Pending);
    expect($orders[1]->status)->toBe(OrderStatus::Confirmed);
    expect($orders[2]->status)->toBe(OrderStatus::Shipped);
});
```

---

## Action Testing

### Testing Actions with DTOs

```php
describe('CreateOrderAction', function () {
    beforeEach(function () {
        $this->action = app(CreateOrderAction::class);
        $this->customer = Customer::factory()->create();
    });

    it('creates order from valid data', function () {
        $data = new CreateOrderData(
            customerId: $this->customer->id,
            items: [
                new OrderItemData(productId: 1, quantity: 2, price: 1000),
            ],
        );

        $order = $this->action->execute($data);

        expect($order)
            ->toBeInstanceOf(Order::class)
            ->customer_id->toBe($this->customer->id)
            ->items->toHaveCount(1);
    });

    it('calculates total from line items', function () {
        $data = new CreateOrderData(
            customerId: $this->customer->id,
            items: [
                new OrderItemData(productId: 1, quantity: 2, price: 1000),
                new OrderItemData(productId: 2, quantity: 1, price: 500),
            ],
        );

        $order = $this->action->execute($data);

        expect($order->total)->toBe(2500); // (2 * 1000) + (1 * 500)
    });

    it('throws when customer not found', function () {
        $data = new CreateOrderData(
            customerId: 99999,
            items: [],
        );

        expect(fn () => $this->action->execute($data))
            ->toThrow(CustomerNotFoundException::class);
    });
});
```

### Testing Actions with Events

```php
use Illuminate\Support\Facades\Event;

describe('ConfirmOrderAction', function () {
    it('dispatches OrderConfirmed event', function () {
        Event::fake([OrderConfirmed::class]);

        $order = Order::factory()->pending()->create();
        $action = app(ConfirmOrderAction::class);

        $action->execute($order);

        Event::assertDispatched(OrderConfirmed::class, function ($event) use ($order) {
            return $event->order->id === $order->id;
        });
    });
});
```

---

## Feature Tests

### Controller Happy Path

```php
describe('POST /orders', function () {
    beforeEach(function () {
        $this->customer = Customer::factory()->create();
        $this->product = Product::factory()->create(['price' => 1000]);
    });

    it('creates order and redirects', function () {
        $response = $this->actingAs($this->customer)
            ->post('/orders', [
                'items' => [
                    ['product_id' => $this->product->id, 'quantity' => 2],
                ],
            ]);

        $response->assertRedirect('/orders');

        $this->assertDatabaseHas('orders', [
            'customer_id' => $this->customer->id,
            'total' => 2000,
        ]);
    });

    it('returns validation errors for empty items', function () {
        $response = $this->actingAs($this->customer)
            ->post('/orders', [
                'items' => [],
            ]);

        $response->assertSessionHasErrors(['items']);
    });
});
```

### API Responses

```php
describe('GET /api/orders', function () {
    it('returns paginated orders', function () {
        $customer = Customer::factory()
            ->has(Order::factory()->count(15))
            ->create();

        $response = $this->actingAs($customer, 'sanctum')
            ->getJson('/api/orders');

        $response
            ->assertOk()
            ->assertJsonCount(10, 'data')
            ->assertJsonPath('meta.total', 15);
    });

    it('returns 401 for unauthenticated request', function () {
        $this->getJson('/api/orders')
            ->assertUnauthorized();
    });
});
```

### JSON Structure Assertions

```php
it('returns order with expected structure', function () {
    $order = Order::factory()
        ->has(OrderItem::factory()->count(2), 'items')
        ->create();

    $response = $this->actingAs($order->customer, 'sanctum')
        ->getJson("/api/orders/{$order->id}");

    $response
        ->assertOk()
        ->assertJsonStructure([
            'data' => [
                'id',
                'status',
                'total',
                'items' => [
                    '*' => ['id', 'product_id', 'quantity', 'price'],
                ],
                'created_at',
            ],
        ]);
});
```

---

## Fluent Assertions

### Chained Property Access

```php
it('asserts nested properties', function () {
    $order = Order::factory()
        ->confirmed()
        ->has(OrderItem::factory()->count(3), 'items')
        ->create();

    expect($order)
        ->status->toBe(OrderStatus::Confirmed)
        ->items->toHaveCount(3)
        ->customer->name->not->toBeEmpty()
        ->total->toBeGreaterThan(0);
});
```

### Higher-Order Expectations

```php
it('asserts each item in collection', function () {
    $orders = Order::factory()->count(5)->create();

    expect($orders)
        ->toHaveCount(5)
        ->each->toBeInstanceOf(Order::class)
        ->each->status->toBe(OrderStatus::Pending);
});
```

### Sequence Assertions

```php
it('asserts sequence of values', function () {
    $items = collect([
        ['name' => 'First', 'price' => 100],
        ['name' => 'Second', 'price' => 200],
        ['name' => 'Third', 'price' => 300],
    ]);

    expect($items)
        ->sequence(
            fn ($item) => $item->name->toBe('First'),
            fn ($item) => $item->price->toBe(200),
            fn ($item) => $item->name->toBe('Third'),
        );
});
```

---

## Database Assertions

### Using expect()

```php
it('persists order to database', function () {
    $action = app(CreateOrderAction::class);
    $data = new CreateOrderData(customerId: 1, items: []);

    $action->execute($data);

    expect(Order::count())->toBe(1);
    expect(Order::first())
        ->customer_id->toBe(1)
        ->status->toBe(OrderStatus::Pending);
});
```

### Using Laravel Assertions

```php
it('creates order with items', function () {
    $action = app(CreateOrderAction::class);
    $data = new CreateOrderData(
        customerId: 1,
        items: [new OrderItemData(productId: 5, quantity: 2, price: 1000)],
    );

    $order = $action->execute($data);

    $this->assertDatabaseHas('orders', [
        'id' => $order->id,
        'customer_id' => 1,
    ]);

    $this->assertDatabaseHas('order_items', [
        'order_id' => $order->id,
        'product_id' => 5,
        'quantity' => 2,
    ]);
});
```

### Soft Deletes

```php
it('soft deletes order', function () {
    $order = Order::factory()->create();

    $order->delete();

    $this->assertSoftDeleted('orders', ['id' => $order->id]);
    expect(Order::withTrashed()->find($order->id))->not->toBeNull();
});
```

---

## Model Testing

### Relationships

```php
describe('Order relationships', function () {
    it('belongs to customer', function () {
        $order = Order::factory()
            ->for(Customer::factory())
            ->create();

        expect($order->customer)->toBeInstanceOf(Customer::class);
    });

    it('has many items', function () {
        $order = Order::factory()
            ->has(OrderItem::factory()->count(3), 'items')
            ->create();

        expect($order->items)
            ->toHaveCount(3)
            ->each->toBeInstanceOf(OrderItem::class);
    });
});
```

### Scopes

```php
describe('Order scopes', function () {
    beforeEach(function () {
        Order::factory()->pending()->count(3)->create();
        Order::factory()->confirmed()->count(2)->create();
        Order::factory()->shipped()->count(1)->create();
    });

    it('filters by status', function () {
        expect(Order::pending()->count())->toBe(3);
        expect(Order::confirmed()->count())->toBe(2);
        expect(Order::shipped()->count())->toBe(1);
    });

    it('chains scopes', function () {
        $customer = Customer::factory()->create();
        Order::factory()->for($customer)->confirmed()->create();

        expect(Order::forCustomer($customer)->confirmed()->count())->toBe(1);
    });
});
```

### Casts and Accessors

```php
describe('Order casts', function () {
    it('casts status to enum', function () {
        $order = Order::factory()->create(['status' => 'confirmed']);

        expect($order->status)->toBeInstanceOf(OrderStatus::class);
        expect($order->status)->toBe(OrderStatus::Confirmed);
    });

    it('casts total to Money', function () {
        $order = Order::factory()->create(['total' => 1000]);

        expect($order->total)
            ->toBeInstanceOf(Money::class)
            ->cents->toBe(1000);
    });
});
```

---

## Datasets

### Named Datasets

```php
dataset('valid_order_data', [
    'single item' => [fn () => new CreateOrderData(
        customerId: 1,
        items: [new OrderItemData(productId: 1, quantity: 1, price: 1000)],
    )],
    'multiple items' => [fn () => new CreateOrderData(
        customerId: 1,
        items: [
            new OrderItemData(productId: 1, quantity: 2, price: 1000),
            new OrderItemData(productId: 2, quantity: 1, price: 500),
        ],
    )],
]);

it('creates order from valid data', function (CreateOrderData $data) {
    $order = app(CreateOrderAction::class)->execute($data);

    expect($order)->toBeInstanceOf(Order::class);
})->with('valid_order_data');
```

### Inline Datasets

```php
it('rejects invalid quantities', function (int $quantity) {
    $data = new OrderItemData(productId: 1, quantity: $quantity, price: 1000);

    expect(fn () => $data->validate())
        ->toThrow(InvalidArgumentException::class);
})->with([0, -1, -100]);
```

### Combined Datasets

```php
it('calculates discount correctly', function (int $total, int $discount, int $expected) {
    $order = Order::factory()->create(['total' => $total]);

    $order->applyDiscount($discount);

    expect($order->total)->toBe($expected);
})->with([
    [1000, 10, 900],   // 10% off
    [1000, 25, 750],   // 25% off
    [1000, 100, 0],    // 100% off
]);
```

---

## Mocking

### Facades

```php
use Illuminate\Support\Facades\Mail;

it('sends order confirmation email', function () {
    Mail::fake();

    $order = Order::factory()->create();
    app(SendOrderConfirmationAction::class)->execute($order);

    Mail::assertSent(OrderConfirmationMail::class, function ($mail) use ($order) {
        return $mail->hasTo($order->customer->email);
    });
});
```

### Partial Mocks

```php
it('calls external API', function () {
    $mock = $this->partialMock(PaymentGateway::class, function ($mock) {
        $mock->shouldReceive('charge')
            ->once()
            ->with(1000, 'tok_test')
            ->andReturn(new PaymentResult(success: true));
    });

    $result = app(ProcessPaymentAction::class)->execute(1000, 'tok_test');

    expect($result->success)->toBeTrue();
});
```

---

## Time Manipulation

```php
use Illuminate\Support\Facades\Date;

describe('Order expiration', function () {
    it('expires after 24 hours', function () {
        $order = Order::factory()->create();

        Date::setTestNow(now()->addHours(25));

        expect($order->fresh()->isExpired())->toBeTrue();
    });

    it('is not expired within 24 hours', function () {
        $order = Order::factory()->create();

        Date::setTestNow(now()->addHours(23));

        expect($order->fresh()->isExpired())->toBeFalse();
    });
});
```

---

## Architecture Tests

```php
arch('actions are invokable')
    ->expect('App\Actions')
    ->toHaveMethod('execute');

arch('models extend base model')
    ->expect('App\Models')
    ->toExtend('App\Models\Model');

arch('controllers are thin')
    ->expect('App\Http\Controllers')
    ->not->toUse(['DB', 'Cache']);

arch('no debugging statements')
    ->expect(['dd', 'dump', 'ray'])
    ->not->toBeUsed();
```
