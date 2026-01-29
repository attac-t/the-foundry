# ViewModel: Examples

Patterns for view data transformation.

---

## The Pattern

### ✅ Form ViewModel (Create/Edit)
**Why?** One class handles both create and edit views.
```php
class PostFormViewModel implements Arrayable
{
    public function __construct(
        private User $user,
        private ?Post $post = null,
    ) {}

    public function post(): Post
    {
        return $this->post ?? new Post();
    }

    public function categories(): Collection
    {
        return Category::allowedForUser($this->user)->get();
    }

    public function toArray(): array
    {
        return [
            'post' => $this->post(),
            'categories' => $this->categories(),
        ];
    }
}
```

---

## Controller Usage

### ✅ Create Action
```php
public function create(): View
{
    return view('posts.form', new PostFormViewModel(current_user()));
}
```

### ✅ Edit Action
```php
public function edit(Post $post): View
{
    return view('posts.form', new PostFormViewModel(current_user(), $post));
}
```

---

## With Spatie Package

### ✅ Using spatie/laravel-view-models
**Why?** Base class provides Arrayable + Responsable.
```php
use Spatie\ViewModels\ViewModel;

class PostFormViewModel extends ViewModel
{
    public function __construct(
        private User $user,
        private ?Post $post = null,
    ) {}

    public function post(): Post
    {
        return $this->post ?? new Post();
    }

    public function categories(): Collection
    {
        return Category::allowedForUser($this->user)->get();
    }
}
```

### ✅ Direct Return (Responsable)
```php
public function create(): PostFormViewModel
{
    // Responsable interface allows direct return
    return new PostFormViewModel(current_user());
}
```

---

## Anti-Pattern: View Composer

### ❌ Don't: Global State
```php
// Hard to trace, implicit dependency
View::composer('posts.*', function ($view) {
    $view->with('categories', Category::all());
});
```

### ✅ Do: Explicit ViewModel
```php
// Clear, testable, traceable
return view('posts.form', new PostFormViewModel($user, $post));
```
