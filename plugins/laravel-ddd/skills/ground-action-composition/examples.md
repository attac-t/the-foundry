# Action Composition: Examples

Patterns for reusable, debuggable action chains.

---

## Good Composition

### ✅ Flat Chain (2 levels)
```php
class CreateOrderAction
{
    public function __construct(
        private CreateOrderLineAction $createLine,
        private CalculateTotalsAction $calculateTotals,
    ) {}

    public function execute(OrderData $data): Order
    {
        $order = Order::create($data->toArray());

        foreach ($data->lines as $line) {
            $this->createLine->execute($order, $line);
        }

        $this->calculateTotals->execute($order);

        return $order;
    }
}
```

---

## Too Deep

### ❌ 5+ Level Chain
```php
// Controller
$this->createOrder->execute($data);
    // → CreateOrderAction
    $this->processOrder->execute($order);
        // → ProcessOrderAction
        $this->validateOrder->execute($order);
            // → ValidateOrderAction
            $this->checkInventory->execute($order);
                // → CheckInventoryAction
                $this->reserveStock->execute($items);
                    // → ReserveStockAction
                    // WHERE IS THE BUG?!
```

### ✅ Flattened
```php
class CreateOrderAction
{
    public function execute(OrderData $data): Order
    {
        $this->validateInventory($data);
        $order = $this->createOrder($data);
        $this->reserveStock($order);

        return $order;
    }

    // Private methods, not separate actions
    private function validateInventory(OrderData $data): void { }
    private function createOrder(OrderData $data): Order { }
    private function reserveStock(Order $order): void { }
}
```

---

## When to Extract

### ✅ Reused Elsewhere
```php
// CalculateTotalsAction is used by:
// - CreateOrderAction
// - UpdateOrderAction
// - RefundOrderAction

// Worth extracting!
```

### ❌ Used Once
```php
// ValidateOrderInventoryBeforeCreationAction
// Only used in CreateOrderAction
// Just make it a private method
```

---

## Constructor Injection

### ✅ Actions as Dependencies
```php
class FulfillOrderAction
{
    public function __construct(
        private ChargePaymentAction $chargePayment,
        private SendConfirmationAction $sendConfirmation,
        private NotifyWarehouseAction $notifyWarehouse,
    ) {}
}
```

### ❌ Resolving in Execute
```php
public function execute(Order $order): void
{
    // Hidden dependencies
    app(ChargePaymentAction::class)->execute($order);
    app(SendConfirmationAction::class)->execute($order);
}
```
