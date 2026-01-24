# Model State: Examples

Patterns from spatie/laravel-model-states.

---

## The Pattern

### ✅ Abstract Base
**Why?** Centralizes transitions. Defines shared interface.
```php
abstract class PaymentState extends State
{
    abstract public function color(): string;

    public static function config(): StateConfig
    {
        return parent::config()
            ->default(Pending::class)
            ->allowTransition(Pending::class, Paid::class)
            ->allowTransition(Pending::class, Failed::class, PendingToFailed::class);
    }
}
```

---

## Common Scenarios

### ✅ Concrete State
```php
class Pending extends PaymentState
{
    public function color(): string
    {
        return 'yellow';
    }
}
```

### ✅ Custom Transition
```php
class PendingToFailed extends Transition
{
    public function __construct(
        private Payment $payment,
        private string $reason,
    ) {}

    public function handle(): Payment
    {
        $this->payment->state = new Failed($this->payment);
        $this->payment->failure_reason = $this->reason;
        $this->payment->save();

        return $this->payment;
    }
}
```

### ✅ Model Integration
```php
class Payment extends Model
{
    use HasStates;

    protected $casts = [
        'state' => PaymentState::class,
    ];
}
```
