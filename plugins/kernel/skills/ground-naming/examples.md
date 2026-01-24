# Naming: Examples

Patterns from production codebases.

---

## Resources (Domain Entities)

**Pattern:** Singular noun, PascalCase.
```pseudo
// Good
User, Order, Product, Category

// Anti-patterns
UserEntity, Users, TblUser, user_record
```

## Flows (Request Handlers)

**Pattern:** Singular resource + Handler suffix (or language convention).
```pseudo
// Resource handlers
UserHandler, OrderHandler, ProductHandler

// Nested actions (single-purpose handlers)
User/ProfileHandler        // GET /users/{user}/profile
Order/InvoiceHandler       // GET /orders/{order}/invoice
Product/InventoryHandler   // PATCH /products/{product}/inventory

// Anti-pattern: God handlers
UserManagementHandler, AdminDashboardHandler
```

## Actions (Business Logic Units)

**Pattern:** VerbNoun - what it does.
```pseudo
// Clear intent
CreateOrder, SendInvoice, CalculateDiscount, ImportProducts
PublishPost, ArchiveProject, SyncInventory, GenerateReport

// Vague (avoid)
OrderService, HandleOrder, ProcessData, DoStuff
```

## Async Tasks

**Pattern:** VerbNoun - async task description.
```pseudo
// Good
SendWelcomeEmail, ProcessPodcast, GenerateThumbnail
SyncOrderToExternal, IndexPriceList, PruneStaleRecords

// Unclear (avoid)
EmailJob, OrderJob, HandleSync
```

## Events

**Pattern:** PastTense - what happened.
```pseudo
// Something happened
OrderCreated, UserRegistered, PaymentReceived, PasswordReset
ProductPublished, SubscriptionCancelled, LoginAttempted

// Not past tense (avoid)
CreateOrder, NewUser, ProcessPayment
```

## Event Handlers

**Pattern:** VerbNoun - reaction to event.
```pseudo
// What it does in response
SendWelcomeEmail        // Handles UserRegistered
NotifyAdmins            // Handles OrderCreated
UpdateSearchIndex       // Handles ProductUpdated
LogFailedLogin          // Handles LoginFailed

// Passive or unclear (avoid)
UserRegisteredHandler, HandleOrderCreated
```

## Middleware (Interceptors)

**Pattern:** VerbNoun or Adjective describing gate.
```pseudo
// Clear gate description
Authenticate, EnsureEmailIsVerified, ThrottleRequests
ValidateSignature, TrimStrings, PreventRequestsDuringMaintenance

// Unclear (avoid)
CheckMiddleware, UserMiddleware
```

---

## Data Transfer Objects

**Pattern:** Noun + Data suffix.
```pseudo
// Good
OrderData, UserData, AddressData, ProductData

// Nested/specific
CreateOrderData, UpdateUserData, OrderItemData

// Inconsistent (avoid)
OrderDTO, UserInfo, OrderPayload
```

## API Resources

**Pattern:** Noun + Resource suffix.
```pseudo
// Good
UserResource, OrderResource, ProductResource

// Collections
UserCollection, OrderCollection
```

---

## Boolean Accessors

**Pattern:** `is`, `has`, `can`, `should`, `was`, `will` prefixes.

```pseudo
// Reads like English
order.isPending()
order.isCompleted()
order.wasCancelled()
user.hasRole('admin')
user.hasVerifiedEmail()
user.canAccessDashboard()
post.shouldBeIndexed()
job.willRetry()

// Ambiguous (avoid)
order.checkStatus()
order.status()        // Returns what? Bool? String?
user.admin()          // Is admin? Has admin? Gets admin?
user.verified()       // Adjective alone is unclear
```

---

## Computed Properties

**Pattern:** Noun phrase.

```pseudo
// Good
fullName
formattedPrice
isActive
totalWithTax
displayName
```

---

## Relationships

**Pattern:** Describe the relationship, not the foreign key.

```pseudo
// Reads naturally
order.customer()          // belongsTo
order.items()             // hasMany
user.orders()             // hasMany
post.author()             // belongsTo (not user!)
product.categories()      // belongsToMany
invoice.payments()        // hasMany

// Technical/foreign-key focused (avoid)
order.user()              // Who? Customer? Creator? Assignee?
order.order_items()       // Redundant
post.user_id()            // Foreign key, not relationship
```

---

## Query Scopes

**Pattern:** Adjective or state description.

```pseudo
// Filter scopes
active()
pending()
published()
recent()

// Parameterized scopes
forUser(user: User)
createdBetween(start, end)
withStatus(status: Status)

// Verbose/redundant (avoid)
whereActive()    // "where" is implied
getPending()     // "get" doesn't belong in scope
```

---

## Query Builders

**Pattern:** Noun + QueryBuilder or Noun + Query.

```pseudo
// Custom query builders
OrderQueryBuilder, ProductQueryBuilder, UserQueryBuilder

// Usage reads naturally
Order.query()
    .active()
    .forCustomer(customer)
    .createdThisMonth()
    .get()
```

---

## Value Objects

**Pattern:** The concept they represent.

```pseudo
// Domain concepts
Money, Percentage, Email, PhoneNumber, Address
DateRange, TimeSlot, Coordinates, Color

// Specific variations
Price, Discount, TaxRate, ExchangeRate

// Technical suffixes (avoid)
MoneyValue, MoneyVO, MoneyObject
```

---

## Enums

**Pattern:** Singular concept, PascalCase values.

```pseudo
// Good
enum OrderStatus {
    Pending = 'pending'
    Processing = 'processing'
    Completed = 'completed'
    Cancelled = 'cancelled'
}

enum PaymentMethod {
    Cash = 'cash'
    Card = 'card'
    BankTransfer = 'bank_transfer'
}

// Plural or verbose (avoid)
enum OrderStatuses { ... }
enum OrderStatusEnum { ... }
```

---

## Interfaces & Contracts

**Pattern:** Capability or role description.

```pseudo
// Capability contracts
Authenticatable, Authorizable, CanResetPassword
ShouldQueue, ShouldBroadcast, ShouldBeUnique
Arrayable, Jsonable, Htmlable, Renderable

// Domain contracts
Purchasable, Discountable, Taxable, Shippable
Exportable, Importable, Searchable

// "Interface" suffix (avoid)
UserInterface       // -> User (in Contracts namespace)
OrderServiceInterface   // -> OrderContract or just the capability
```

---

## Mixins (Traits)

**Pattern:** HasX, WithX, CanX, InteractsWithX.

```pseudo
// Good
HasFactory, HasUuids, HasTimestamps
SoftDeletes, Notifiable, Searchable
InteractsWithQueue, InteractsWithMedia

// Capability mixins
CanBePurchased, CanBeDiscounted
HasPricing, HasInventory, HasAuditLog

// Unclear (avoid)
OrderTrait, UserMixin
```

---

## Collections

**Pattern:** Plural for collections, singular for items.

```pseudo
// Clear plurality
orders = Order.all()           // Collection of orders
order = Order.find(1)          // Single order
orderItems = order.items       // Collection of items
firstItem = orderItems.first() // Single item

// Custom collections
OrderCollection, ProductCollection
```

---

## Variables

**Pattern:** Specific, typed, contextual.

```pseudo
// Specific names
function execute(order: Order, customer: Customer): Invoice
pendingOrders = Order.pending().get()
totalAmount = order.calculateTotal()
activeUsers = User.active().count()

// Generic names (avoid)
function execute(data, params)
result = this.process(input)
temp = order.items
x = User.count()
```

---

## Function/Method Names

**Pattern:** Verb + specific noun/context.

```pseudo
// Clear actions
calculateTotal(), calculateTax(), calculateDiscount()
sendNotification(), sendEmail(), sendSms()
validateOrder(), validateAddress(), validatePayment()
generateInvoice(), generateReport(), generatePdf()

// Vague verbs (avoid)
handle(), process(), execute(), run(), do()
getData(), setData(), processData()
```

---

## Anti-Pattern Gallery

### The Lazy Suffixes
```pseudo
// NEVER use these without specificity
OrderManager      // Manages what exactly?
OrderHandler      // Handles what operation?
OrderService      // What service does it provide?
OrderHelper       // Helper for what?
OrderUtils        // Utility doing what?
OrderProcessor    // Processes how?

// Be specific
OrderTotalCalculator
OrderStatusUpdater
OrderExporter
OrderValidator
```

### The Redundant Prefix
```pseudo
// Namespace already provides context
Domain/Orders/Entities/OrderEntity
App/Services/OrderService/OrderServiceUnit

// Let namespace do the work
Domain/Orders/Entities/Order
Domain/Orders/Actions/CreateOrder
```

### The Abbreviation Trap
```pseudo
// Cryptic abbreviations (avoid)
ord, cust, prod, inv
calcTot(), genRpt(), valAddr()
UsrCtrl, OrdSvc

// Full words (IDE autocomplete exists)
order, customer, product, invoice
calculateTotal(), generateReport(), validateAddress()
UserHandler, OrderService
```
