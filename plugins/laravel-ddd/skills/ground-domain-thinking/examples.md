# Domain Thinking: Examples

Patterns for business-aligned code structure.

---

## Naming

### ❌ Technical Names
```
app/Services/InvoiceService.php
app/Repositories/OrderRepository.php
app/Helpers/PaymentHelper.php
```

### ✅ Domain Names
```
src/Domain/Invoicing/Actions/CreateInvoiceAction.php
src/Domain/Orders/Models/Order.php
src/Domain/Payments/Events/PaymentReceived.php
```

---

## Structure

### ❌ Technical Grouping
```
app/
├── Controllers/
├── Models/
├── Services/
└── Repositories/
```

### ✅ Domain Grouping
```
src/Domain/
├── Invoicing/
│   ├── Actions/
│   ├── Models/
│   └── Events/
├── Orders/
└── Payments/
```

---

## Language

### ❌ Developer Speak
```php
// What does "process" mean?
$service->processOrder($order);

// Generic, meaningless
$handler->handle($data);
```

### ✅ Business Speak
```php
// Clear intent
$this->fulfillOrder->execute($order);

// Domain language
$this->markAsPaid->execute($invoice);
```

---

## Discovery

### The Process
```
1. Client says: "We need to track when invoices are overdue"

2. You hear: "overdue" is a domain concept
   - Not a boolean flag
   - Not a status string
   - A state with behavior

3. You model:
   class OverdueInvoiceState extends InvoiceState
   {
       public function canSendReminder(): bool
       {
           return true;
       }
   }

4. Client recognizes the code
```
