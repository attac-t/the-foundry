# Builder: Examples

Real-world examples of the Builder pattern decision.

---

## Laravel Framework

### ✅ Query Builder
**Why?** SQL queries have many optional clauses.
```php
DB::table('users')
    ->where('active', true)
    ->orderBy('name')
    ->limit(10)
    ->get();
```

### ✅ Mail Builder
**Why?** Emails have optional recipients, attachments, headers.
```php
Mail::to($user)
    ->cc($manager)
    ->bcc($admin)
    ->send(new OrderConfirmation($order));
```

### ✅ Notification Builder
**Why?** On-demand routing with optional channels.
```php
Notification::route('mail', $email)
    ->route('slack', $webhook)
    ->notify(new AlertNotification);
```

---

## Spatie Packages

### ✅ Activity Logger
**Why?** Logging has many optional context fields.
```php
activity()
    ->causedBy($user)
    ->performedOn($order)
    ->withProperties(['status' => 'shipped'])
    ->log('Order shipped');
```

### ✅ Media Library
**Why?** Media attachment has optional conversions, collections.
```php
$model->addMedia($file)
    ->usingName('Avatar')
    ->toMediaCollection('avatars');
```

---

## Production Patterns

### ✅ Price Lookup (Your Codebase)
**Why?** Price resolution depends on location, channel, customer.
```php
Price::for($item)
    ->at($location)
    ->via($channel)
    ->forCustomer($customer)
    ->best();
```

### ✅ Navigation Config
**Why?** Navigation has many optional tabs, filters, defaults.
```php
NavigationConfigBuilder::forUser($user)
    ->withTabs($tabs)
    ->withDefaults()
    ->build();
```
