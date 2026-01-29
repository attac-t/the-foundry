# Action: Composition Patterns

Action composition and fluent builders.

---

## Action Calls Action

### ✅ Reuse Logic
**Why?** Avoid deep chains (max 3-4 levels).
```php
class CreateInvoiceAction
{
    public function __construct(
        private CreateInvoiceLineAction $createLine,
        private CalculateTotalsAction $calculateTotals,
    ) {}

    public function execute(InvoiceData $data): Invoice
    {
        $invoice = Invoice::create($data->except('lines')->all());

        foreach ($data->lines as $line) {
            $this->createLine->execute($invoice, $line);
        }

        $this->calculateTotals->execute($invoice);

        return $invoice->fresh();
    }
}
```

---

## Fluent Builder Action

### ✅ Complex Orchestration
**Why?** When execution has many optional steps.
```php
class UpsertAccountingSegmentAction
{
    private ?Account $account = null;
    private bool $skipValidation = false;

    public function forAccount(Account $account): self
    {
        $clone = clone $this;
        $clone->account = $account;
        return $clone;
    }

    public function skipValidation(): self
    {
        $clone = clone $this;
        $clone->skipValidation = true;
        return $clone;
    }

    public function execute(SegmentData $data): Segment
    {
        if (! $this->skipValidation) {
            $this->validate($data);
        }

        return Segment::updateOrCreate(
            ['account_id' => $this->account->id, 'code' => $data->code],
            $data->all(),
        );
    }
}

// Usage:
$action->forAccount($account)->skipValidation()->execute($data);
```
