# Elegance: Examples

Code smells that signal resistance. When you see these, **STOP and rethink**.

---

## Fighting the Abstraction

> "If it feels hard, you're fighting the abstraction."

### 🚩 Fighting the Container
**Why?** Manual instantiation ignores Laravel's core strength.
```php
// ❌ You're doing the container's job
$mailer = new Mailer(new SmtpTransport(config('mail.host'), config('mail.port')));
$logger = new Logger(new FileHandler(storage_path('logs')));
$service = new OrderService($mailer, $logger);

// ✅ Let the container wire dependencies
public function __construct(private OrderService $service) {}
```

### 🚩 Fighting Relationships
**Why?** Manual joins when Eloquent relationships exist.
```php
// ❌ Raw SQL for something Eloquent does beautifully
$orders = DB::table('orders')
    ->join('users', 'orders.user_id', '=', 'users.id')
    ->where('users.id', $userId)
    ->select('orders.*')
    ->get();

// ✅ Define once, use everywhere
$orders = $user->orders; // belongsTo defined on model
```

### 🚩 Fighting Immutability
**Why?** Spatie Data is immutable by design. Don't mutate.
```php
// ❌ Trying to change DTO state
$data = OrderData::from($request);
$data->status = 'paid'; // Fighting the design

// ✅ Create new instance with changes
$data = $data->with(status: 'paid');
```

---

## Wrong Shape

> "The code is telling you it's not in the right shape."

### 🚩 Prop Drilling
**Why?** Passing context through 5 layers means wrong boundaries.
```php
// ❌ Tenant flows through everything
Controller → Action → Service → Repository → Query
    ↓           ↓          ↓           ↓         ↓
 $tenant    $tenant    $tenant     $tenant   $tenant

// ✅ Set context once, access globally
app(TenantContext::class)->set($tenant);
// Or use Laravel's scoped bindings
```

### 🚩 Method Needs a Meeting
**Why?** When a method needs data from unrelated sources, it's doing too much.
```php
// ❌ This method knows too much about the world
function processOrder(Order $order, User $user, Config $config,
    Logger $logger, Mailer $mailer, TaxService $tax) { ... }

// ✅ Wrong shape — should be an Action with injected deps
class ProcessOrderAction {
    public function __construct(
        private TaxService $tax,
        private Mailer $mailer,
    ) {}
    public function execute(Order $order): void { ... }
}
```

### 🚩 Tests Need the Universe
**Why?** Hard-to-test code is poorly designed code.
```php
// ❌ 30 lines of setup = design smell
$user = User::factory()->create();
$org = Organization::factory()->for($user)->create();
$location = Location::factory()->for($org)->create();
$register = Register::factory()->for($location)->create();
// ... finally the actual test

// ✅ If mocking everything, the coupling is wrong
// Refactor until: $action->execute($order) is testable standalone
```

---

## Red Flags

### 🚩 The "Manager" Class
**Why?** Vague suffix, multiple responsibilities.
```php
// ❌ OrderManager::create(), invoice(), ship(), cancel(), refund()
// ✅ CreateOrderAction, GenerateInvoiceAction, ShipOrderAction
```

### 🚩 The "Helper" Dumping Ground
**Why?** Static utilities that belong on objects.
```php
// ❌ OrderHelper::formatTotal($order), getCustomerName($order)
// ✅ $order->formattedTotal(), $order->customer->name
```

---

## Unnecessary Indirection

### 🚩 The Passthrough Method
**Why?** If it just calls another method with same args, delete it.
```php
// ❌ OrderRepository::find($id) { return $this->model->find($id); }
// ✅ Order::find($id)
```

### 🚩 Interface for Single Implementation
**Why?** Premature abstraction. Add interface when you need a second impl.
```php
// ❌ interface OrderRepositoryInterface + single OrderRepository
// ✅ Order::find($id)
```

---

## Type Safety

### 🚩 The Config Array
**Why?** Untyped, no IDE support.
```php
// ❌ $pdf->generate(['size' => 'A4', 'color' => true])
// ✅ $pdf->generate(new PdfConfig(size: PdfSize::A4, color: true))
```

### 🚩 Primitive Obsession
**Why?** Domain concepts deserve objects.
```php
// ❌ charge(int $amount, string $currency)
// ✅ charge(Money $amount)
```

### 🚩 Long Parameter Lists
**Why?** More than 3 params? You're missing a DTO.
```php
// ❌ createOrder($customerId, $address, $city, $postcode, $country, $items)
// ✅ createOrder(CreateOrderData $data)
```

---

## Control Flow

### 🚩 Deep Nesting
**Why?** More than 2 levels deep = fighting the code.
```php
// ❌ if ($order) { if ($order->isValid()) { if ($order->hasItems()) { ... } } }
// ✅ Early returns, then flat logic
```

### 🚩 Boolean Parameters
**Why?** Hidden branches. Caller can't understand behavior.
```php
// ❌ sendEmail($user, true, false)
// ✅ sendWelcomeEmail($user) or ValidationMode::Skip
```

### 🚩 Temporal Coupling
**Why?** Methods that must be called in order.
```php
// ❌ $p->setOrder(); $p->setCustomer(); $p->validate(); $p->process();
// ✅ new OrderProcessor($order, $customer)->process()
```

---

## Design Smells

### 🚩 Defensive Programming
**Why?** Excessive null checks = unclear contracts.
```php
// ❌ if ($order === null) { if ($order->customer === null) { ... } }
// ✅ Type hints: process(Order $order): Invoice
```

### 🚩 Feature Envy
**Why?** Method uses another object's data more than its own.
```php
// ❌ InvoiceGenerator reaching into $order->items, $order->shipping, $order->taxRate
// ✅ $order->calculateTotal() — tell, don't ask
```

### 🚩 Comments Explaining Why
**Why?** If you need to explain complexity, the code is wrong.
```php
// ❌ // We need to check if order is valid because legacy system bug...
// ✅ if ($order->canBeProcessed())
```

---

## The Taylor Test

> "Would Taylor Otwell approve of this code?"

If explaining why it *has* to be complex, you've failed. Elegant code looks **inevitable**.
