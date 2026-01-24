# Elegance: Examples

Code smells that signal resistance. When you see these, **STOP and rethink**.

---

## Fighting the Abstraction

> "If it feels hard, you're fighting the abstraction."

### Fighting the Container
**Why?** Manual instantiation ignores dependency injection's core strength.
```pseudo
// You're doing the container's job
mailer = new Mailer(new SmtpTransport(config.mail.host, config.mail.port))
logger = new Logger(new FileHandler(paths.logs))
service = new OrderService(mailer, logger)

// Let the container wire dependencies
constructor(private service: OrderService) {}
```

### Fighting Relationships
**Why?** Manual joins when ORM relationships exist.
```pseudo
// Raw queries for something the ORM does beautifully
orders = database.table('orders')
    .join('users', 'orders.user_id', '=', 'users.id')
    .where('users.id', userId)
    .select('orders.*')
    .get()

// Define once, use everywhere
orders = user.orders  // relationship defined on resource
```

### Fighting Immutability
**Why?** DTOs are immutable by design. Don't mutate.
```pseudo
// Trying to change DTO state
data = OrderData.from(request)
data.status = 'paid'  // Fighting the design

// Create new instance with changes
data = data.with(status: 'paid')
```

---

## Wrong Shape

> "The code is telling you it's not in the right shape."

### Prop Drilling
**Why?** Passing context through 5 layers means wrong boundaries.
```pseudo
// Tenant flows through everything
Flow -> Action -> Service -> Repository -> Query
  |        |         |           |          |
tenant  tenant    tenant      tenant     tenant

// Set context once, access globally
app.context(TenantContext).set(tenant)
// Or use scoped bindings
```

### Capability Needs a Meeting
**Why?** When a capability needs data from unrelated sources, it's doing too much.
```pseudo
// This capability knows too much about the world
function processOrder(order, user, config, logger, mailer, taxService) { ... }

// Wrong shape -- should be an Action with injected deps
ProcessOrderAction {
    constructor(
        private taxService: TaxService,
        private mailer: Mailer,
    ) {}
    execute(order: Order): void { ... }
}
```

### Tests Need the Universe
**Why?** Hard-to-test code is poorly designed code.
```pseudo
// 30 lines of setup = design smell
user = User.factory().create()
org = Organization.factory().for(user).create()
location = Location.factory().for(org).create()
register = Register.factory().for(location).create()
// ... finally the actual test

// If mocking everything, the coupling is wrong
// Refactor until: action.execute(order) is testable standalone
```

---

## Red Flags

### The "Manager" Unit
**Why?** Vague suffix, multiple responsibilities.
```pseudo
// OrderManager.create(), invoice(), ship(), cancel(), refund()
// Better: CreateOrderAction, GenerateInvoiceAction, ShipOrderAction
```

### The "Helper" Dumping Ground
**Why?** Static utilities that belong on objects.
```pseudo
// OrderHelper.formatTotal(order), getCustomerName(order)
// Better: order.formattedTotal(), order.customer.name
```

---

## Unnecessary Indirection

### The Passthrough Capability
**Why?** If it just calls another capability with same args, delete it.
```pseudo
// OrderRepository.find(id) { return this.resource.find(id) }
// Better: Order.find(id)
```

### Interface for Single Implementation
**Why?** Premature abstraction. Add interface when you need a second impl.
```pseudo
// interface OrderRepositoryInterface + single OrderRepository
// Better: Order.find(id)
```

---

## Type Safety

### The Config Array
**Why?** Untyped, no IDE support.
```pseudo
// pdf.generate(['size' => 'A4', 'color' => true])
// Better: pdf.generate(new PdfConfig(size: PdfSize.A4, color: true))
```

### Primitive Obsession
**Why?** Domain concepts deserve objects.
```pseudo
// charge(amount: int, currency: string)
// Better: charge(amount: Money)
```

### Long Parameter Lists
**Why?** More than 3 params? You're missing a DTO.
```pseudo
// createOrder(customerId, address, city, postcode, country, items)
// Better: createOrder(data: CreateOrderData)
```

---

## Control Flow

### Deep Nesting
**Why?** More than 2 levels deep = fighting the code.
```pseudo
// if (order) { if (order.isValid()) { if (order.hasItems()) { ... } } }
// Better: Early returns, then flat logic
```

### Boolean Parameters
**Why?** Hidden branches. Caller can't understand behavior.
```pseudo
// sendEmail(user, true, false)
// Better: sendWelcomeEmail(user) or ValidationMode.Skip
```

### Temporal Coupling
**Why?** Capabilities that must be called in order.
```pseudo
// p.setOrder(); p.setCustomer(); p.validate(); p.process();
// Better: new OrderProcessor(order, customer).process()
```

---

## Design Smells

### Defensive Programming
**Why?** Excessive null checks = unclear contracts.
```pseudo
// if (order === null) { if (order.customer === null) { ... } }
// Better: Type hints: process(order: Order): Invoice
```

### Feature Envy
**Why?** Capability uses another object's data more than its own.
```pseudo
// InvoiceGenerator reaching into order.items, order.shipping, order.taxRate
// Better: order.calculateTotal() -- tell, don't ask
```

### Comments Explaining Why
**Why?** If you need to explain complexity, the code is wrong.
```pseudo
// // We need to check if order is valid because legacy system bug...
// Better: if (order.canBeProcessed())
```

---

## The Quality Test

> "Would the framework author approve of this code?"

If explaining why it *has* to be complex, you've failed. Elegant code looks **inevitable**.
