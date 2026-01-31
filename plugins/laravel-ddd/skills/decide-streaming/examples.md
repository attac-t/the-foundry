# Streaming vs Chunking: Examples

When to use each data processing pattern.

---

## Load All

### ✅ Small, Known Dataset
```php
// Always <100 categories
$categories = Category::all();

foreach ($categories as $category) {
    $this->processCategory($category);
}
```

### ✅ Need Multiple Passes
```php
// Must iterate twice
$orders = Order::whereDate('created_at', today())->get();

$total = $orders->sum('total');
$average = $orders->avg('total');
$byStatus = $orders->groupBy('status');
```

---

## Chunking

### ✅ Batch Database Operations
```php
// Process 1000 at a time
User::where('needs_update', true)
    ->chunkById(1000, function ($users) {
        foreach ($users as $user) {
            $user->update(['processed_at' => now()]);
        }
    });
```

### ✅ Batch API Calls
```php
// API accepts max 100 per request
Order::whereNull('synced_at')
    ->chunk(100, function ($orders) {
        $this->api->syncBatch($orders->toArray());

        Order::whereIn('id', $orders->pluck('id'))
            ->update(['synced_at' => now()]);
    });
```

---

## Streaming

### ✅ Large Export
```php
// Could be millions of rows
return response()->streamDownload(function () {
    $handle = fopen('php://output', 'w');

    Invoice::query()
        ->cursor()  // Streams from DB
        ->each(function ($invoice) use ($handle) {
            fputcsv($handle, $invoice->toExportArray());
        });

    fclose($handle);
}, 'invoices.csv');
```

### ✅ Memory-Constrained Processing
```php
// Don't load all into memory
Invoice::where('status', 'pending')
    ->cursor()
    ->each(function ($invoice) {
        $this->processInvoice->execute($invoice);
    });
```

### ✅ Lazy Collection Aggregation
```php
// Stream and aggregate without loading all
$total = Invoice::query()
    ->cursor()
    ->sum(fn ($invoice) => $invoice->total_price);
```

---

## Anti-Patterns

### ❌ Load All for Large Dataset
```php
// Memory bomb waiting to happen
$invoices = Invoice::all();  // 500K records = crash

foreach ($invoices as $invoice) {
    // Too late, already OOM
}
```

### ❌ Stream When You Need Random Access
```php
// Cursor doesn't support this
$invoices = Invoice::cursor();
$first = $invoices[0];  // Error!
$count = $invoices->count();  // Iterates entire set!
```

---

## Memory Comparison

```
Dataset: 100,000 invoices

Load All:  ~500MB memory, instant random access
Chunk:     ~50MB memory (1K batch), batch boundaries
Stream:    ~5MB memory, row-by-row only

Choose based on constraints, not habit.
```
