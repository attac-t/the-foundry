# Controller: Examples

Patterns from Laravel conventions.

---

## CRUDDY by Design

### ✅ Resource Controller
**Why?** Laravel's implicit routing matches these 7 methods.
```php
class PostController
{
    public function index(): View { }      // GET /posts
    public function create(): View { }     // GET /posts/create
    public function store(Request): Redirect { }   // POST /posts
    public function show(Post): View { }   // GET /posts/{post}
    public function edit(Post): View { }   // GET /posts/{post}/edit
    public function update(Request, Post): Redirect { } // PUT /posts/{post}
    public function destroy(Post): Redirect { } // DELETE /posts/{post}
}
```

### ✅ Single-Action Controller
**Why?** When action doesn't fit CRUD, use `__invoke`.
```php
class PublishPostController
{
    public function __invoke(Post $post): RedirectResponse
    {
        // POST /posts/{post}/publish
    }
}
```

---

## The Flow

### ✅ Validate → Transact → Execute → Respond
```php
public function store(CreateOrderData $data): RedirectResponse
{
    $order = DB::transaction(fn () =>
        $this->createOrder->execute($data)
    );

    return redirect()->route('orders.show', $order);
}
```

---

## Nested Resources

### ✅ CRUDDY Nesting
**Why?** Break god-controllers into focused nested controllers.
```php
// routes/web.php
Route::resource('posts.comments', CommentController::class);

// CommentController - scoped to Post
public function store(Post $post, CreateCommentData $data): RedirectResponse
{
    $comment = $this->createComment->execute($post, $data);
    return back();
}
```
