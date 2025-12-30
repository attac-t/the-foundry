# Naming: Examples

Patterns from Laravel, Spatie, and production.

---

## Laravel Framework Conventions

### Models
**Pattern:** Singular noun, PascalCase.
```php
// ✅ Laravel convention
User, Order, Product, Category

// ❌ Anti-patterns
UserModel, Users, TblUser, user_model
```

### Controllers
**Pattern:** Singular resource + Controller.
```php
// ✅ Resource controllers
UserController, OrderController, ProductController

// ✅ CRUDDY nested actions (single-action controllers)
User\ProfileController        // GET /users/{user}/profile
Order\InvoiceController       // GET /orders/{order}/invoice
Product\InventoryController   // PATCH /products/{product}/inventory

// ❌ God controllers
UserManagementController, AdminDashboardController
```

### Actions
**Pattern:** VerbNoun - what it does.
```php
// ✅ Clear intent
CreateOrder, SendInvoice, CalculateDiscount, ImportProducts
PublishPost, ArchiveProject, SyncInventory, GenerateReport

// ❌ Vague
OrderService, HandleOrder, ProcessData, DoStuff
```

### Jobs
**Pattern:** VerbNoun - async task description.
```php
// ✅ Laravel conventions
SendWelcomeEmail, ProcessPodcast, GenerateThumbnail
SyncOrderToShopify, IndexPriceList, PruneStaleRecords

// ❌ Unclear
EmailJob, OrderJob, HandleSync
```

### Events
**Pattern:** PastTense - what happened.
```php
// ✅ Something happened
OrderCreated, UserRegistered, PaymentReceived, PasswordReset
ProductPublished, SubscriptionCancelled, LoginAttempted

// ❌ Not past tense
CreateOrder, NewUser, ProcessPayment
```

### Listeners
**Pattern:** VerbNoun - reaction to event.
```php
// ✅ What it does in response
SendWelcomeEmail        // Listens to UserRegistered
NotifyAdmins            // Listens to OrderCreated
UpdateSearchIndex       // Listens to ProductUpdated
LogFailedLogin          // Listens to LoginFailed

// ❌ Passive or unclear
UserRegisteredListener, HandleOrderCreated
```

### Middleware
**Pattern:** VerbNoun or Adjective describing gate.
```php
// ✅ Clear gate description
Authenticate, EnsureEmailIsVerified, ThrottleRequests
ValidateSignature, TrimStrings, PreventRequestsDuringMaintenance

// ❌ Unclear
CheckMiddleware, UserMiddleware
```

---

## Spatie Conventions

### Data (DTOs)
**Pattern:** Noun + Data suffix.
```php
// ✅ Spatie Laravel Data
OrderData, UserData, AddressData, ProductData

// ✅ Nested/specific
CreateOrderData, UpdateUserData, OrderItemData

// ❌ Inconsistent
OrderDTO, UserInfo, OrderPayload
```

### Resources
**Pattern:** Noun + Resource suffix.
```php
// ✅ API Resources
UserResource, OrderResource, ProductResource

// ✅ Collections
UserCollection, OrderCollection
```

---

## Boolean Methods

**Pattern:** `is`, `has`, `can`, `should`, `was`, `will` prefixes.

```php
// ✅ Read like English
$order->isPending()
$order->isCompleted()
$order->wasCancelled()
$user->hasRole('admin')
$user->hasVerifiedEmail()
$user->canAccessDashboard()
$post->shouldBeIndexed()
$job->willRetry()

// ❌ Ambiguous
$order->checkStatus()
$order->status()        // Returns what? Bool? String?
$user->admin()          // Is admin? Has admin? Gets admin?
$user->verified()       // Adjective alone is unclear
```

---

## Accessor/Mutator Methods

**Pattern:** Noun phrase (Laravel auto-converts).

```php
// ✅ Laravel 9+ Attribute syntax
protected function fullName(): Attribute
protected function formattedPrice(): Attribute
protected function isActive(): Attribute        // becomes $model->is_active

// ✅ Computed properties (read-only)
protected function totalWithTax(): Attribute
protected function displayName(): Attribute
```

---

## Relationship Methods

**Pattern:** Describe the relationship, not the foreign key.

```php
// ✅ Reads naturally
$order->customer()          // belongsTo
$order->items()             // hasMany
$user->orders()             // hasMany
$post->author()             // belongsTo (not user!)
$product->categories()      // belongsToMany
$invoice->payments()        // hasMany

// ❌ Technical/foreign-key focused
$order->user()              // Who? Customer? Creator? Assignee?
$order->order_items()       // Redundant
$post->user_id()            // Foreign key, not relationship
```

---

## Scopes

**Pattern:** Adjective or state description.

```php
// ✅ Filter scopes
scopeActive($query)         // ->active()
scopePending($query)        // ->pending()
scopePublished($query)      // ->published()
scopeRecent($query)         // ->recent()

// ✅ Parameterized scopes
scopeForUser($query, User $user)      // ->forUser($user)
scopeCreatedBetween($query, $start, $end)
scopeWithStatus($query, Status $status)

// ❌ Verbose/redundant
scopeWhereActive($query)    // ->whereActive() - "where" is implied
scopeGetPending($query)     // ->getPending() - "get" doesn't belong
```

---

## Query Builders

**Pattern:** Noun + QueryBuilder or Noun + Query.

```php
// ✅ Custom query builders
OrderQueryBuilder, ProductQueryBuilder, UserQueryBuilder

// ✅ Usage reads naturally
Order::query()
    ->active()
    ->forCustomer($customer)
    ->createdThisMonth()
    ->get();
```

---

## Value Objects

**Pattern:** The concept they represent.

```php
// ✅ Domain concepts
Money, Percentage, Email, PhoneNumber, Address
DateRange, TimeSlot, Coordinates, Color

// ✅ Specific variations
Price, Discount, TaxRate, ExchangeRate

// ❌ Technical suffixes
MoneyValue, MoneyVO, MoneyObject
```

---

## Enums

**Pattern:** Singular concept, PascalCase values.

```php
// ✅ Laravel 11 / PHP 8.1+
enum OrderStatus: string {
    case Pending = 'pending';
    case Processing = 'processing';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}

enum PaymentMethod: string {
    case Cash = 'cash';
    case Card = 'card';
    case BankTransfer = 'bank_transfer';
}

// ❌ Plural or verbose
enum OrderStatuses { ... }
enum OrderStatusEnum { ... }
```

---

## Interfaces & Contracts

**Pattern:** Capability or role description.

```php
// ✅ Laravel conventions (Contracts namespace)
Authenticatable, Authorizable, CanResetPassword
ShouldQueue, ShouldBroadcast, ShouldBeUnique
Arrayable, Jsonable, Htmlable, Renderable

// ✅ Domain contracts
Purchasable, Discountable, Taxable, Shippable
Exportable, Importable, Searchable

// ❌ "Interface" suffix (use sparingly)
UserInterface       // → User (in Contracts namespace)
OrderServiceInterface   // → OrderContract or just the capability
```

---

## Traits

**Pattern:** HasX, WithX, CanX, InteractsWithX.

```php
// ✅ Laravel conventions
HasFactory, HasUuids, HasTimestamps
SoftDeletes, Notifiable, Searchable
InteractsWithQueue, InteractsWithMedia

// ✅ Capability traits
CanBePurchased, CanBeDiscounted
HasPricing, HasInventory, HasAuditLog

// ❌ Unclear
OrderTrait, UserMixin
```

---

## Collections

**Pattern:** Plural for collections, singular for items.

```php
// ✅ Clear plurality
$orders = Order::all();           // Collection of orders
$order = Order::find(1);          // Single order
$orderItems = $order->items;      // Collection of items
$firstItem = $orderItems->first(); // Single item

// ✅ Custom collections
OrderCollection, ProductCollection
```

---

## Variables

**Pattern:** Specific, typed, contextual.

```php
// ✅ Specific names
public function execute(Order $order, Customer $customer): Invoice
$pendingOrders = Order::pending()->get();
$totalAmount = $order->calculateTotal();
$activeUsers = User::active()->count();

// ❌ Generic names
public function execute($data, $params)
$result = $this->process($input);
$temp = $order->items;
$x = User::count();
```

---

## Method Names

**Pattern:** Verb + specific noun/context.

```php
// ✅ Clear actions
calculateTotal(), calculateTax(), calculateDiscount()
sendNotification(), sendEmail(), sendSms()
validateOrder(), validateAddress(), validatePayment()
generateInvoice(), generateReport(), generatePdf()

// ❌ Vague verbs
handle(), process(), execute(), run(), do()
getData(), setData(), processData()
```

---

## Anti-Pattern Gallery

### The Lazy Suffixes
```php
// ❌ NEVER use these without specificity
OrderManager      // Manages what exactly?
OrderHandler      // Handles what operation?
OrderService      // What service does it provide?
OrderHelper       // Helper for what?
OrderUtils        // Utility doing what?
OrderProcessor    // Processes how?

// ✅ Be specific
OrderTotalCalculator
OrderStatusUpdater
OrderExporter
OrderValidator
```

### The Redundant Prefix
```php
// ❌ Namespace already provides context
Domain\Orders\Models\OrderModel
App\Services\OrderService\OrderServiceClass

// ✅ Let namespace do the work
Domain\Orders\Models\Order
Domain\Orders\Actions\CreateOrder
```

### The Abbreviation Trap
```php
// ❌ Cryptic abbreviations
$ord, $cust, $prod, $inv
calcTot(), genRpt(), valAddr()
UsrCtrl, OrdSvc

// ✅ Full words (IDE autocomplete exists)
$order, $customer, $product, $invoice
calculateTotal(), generateReport(), validateAddress()
UserController, OrderService
```
