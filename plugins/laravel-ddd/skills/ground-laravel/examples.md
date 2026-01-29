# Laravel Philosophy: Examples

Patterns that embrace the framework.

---

## Convention Over Configuration

### ✅ Follow Laravel Defaults
**Why?** Every deviation is cognitive load for future developers.
```php
// Good: Standard naming
app/Models/User.php
app/Http/Controllers/UserController.php
app/Policies/UserPolicy.php

// Bad: Custom structure without documented reason
app/Entities/UserEntity.php
app/Http/Handlers/UserHandler.php
```

### ✅ Use Implicit Route Model Binding
```php
// Good: Let Laravel resolve the model
Route::get('/posts/{post}', [PostController::class, 'show']);

public function show(Post $post)
{
    return view('posts.show', compact('post'));
}

// Bad: Manual resolution
public function show(int $id)
{
    $post = Post::findOrFail($id);
    return view('posts.show', compact('post'));
}
```

---

## Eloquent as Truth

### ✅ Models Own Their Domain
```php
// Good: Logic lives on the model
class Order extends Model
{
    public function markAsPaid(): void
    {
        $this->update(['paid_at' => now()]);
        OrderPaid::dispatch($this);
    }

    public function isPaid(): bool
    {
        return $this->paid_at !== null;
    }
}

// Bad: Wrapping Eloquent in a repository
class OrderRepository
{
    public function markAsPaid(Order $order): void
    {
        $order->update(['paid_at' => now()]);
    }
}
```

---

## Batteries Included

### ✅ Use Laravel Features First
```php
// Good: Built-in authorization
Gate::define('edit-post', fn (User $user, Post $post) => $user->id === $post->user_id);

// Bad: Custom authorization layer
class CustomAuthorizer
{
    public function canEdit(User $user, Post $post): bool
    {
        return $user->id === $post->user_id;
    }
}
```

### ✅ Prefer Spatie Over Custom
```php
// Good: Battle-tested package
use Spatie\ModelStates\State;

class OrderState extends State
{
    // ...
}

// Bad: Custom state machine from scratch
class CustomStateMachine
{
    // 200 lines of untested code...
}
```

---

## Anti-Patterns

### ❌ Fighting the Framework
```php
// Bad: Avoiding Eloquent "for performance"
DB::table('users')->where('id', $id)->first();

// Good: Trust Eloquent, measure if slow
User::find($id);
```

### ❌ Over-Abstracting
```php
// Bad: Service that just calls model
class UserService
{
    public function create(array $data): User
    {
        return User::create($data);  // Why does this exist?
    }
}

// Good: Action with real logic
class CreateUserAction
{
    public function execute(CreateUserData $data): User
    {
        $user = User::create($data->all());
        WelcomeEmail::dispatch($user);
        return $user;
    }
}
```
