# Factory States: Examples

Expressive factories as a DSL.

---

## The Pattern

### Simple State
**Why?** Readability over flexibility.
```php
// Bad
$doc = Document::factory()->create(['title' => 'Draft']);

// Good
$doc = Document::factory()->titled('Draft')->create();
```

```php
public function titled(string $title): static
{
    return $this->state(['title' => $title]);
}
```

---

## Common Scenarios

### Relationship State
```php
public function withChapters(int $count = 2): static
{
    return $this->has(Chapter::factory()->count($count), 'chapters');
}
```

### Deep Hierarchy
```php
public function withDeepHierarchy(): static
{
    return $this->has(
        Chapter::factory()
            ->count(2)
            ->has(Paragraph::factory()->count(2), 'paragraphs'),
        'chapters'
    );
}
```

### After-Create Action
```php
public function revised(): static
{
    return $this->afterCreating(fn (Document $d) => $d->revise('initial'));
}
```

### Composition
```php
$doc = Document::factory()
    ->titled('Draft')
    ->withChapters(3)
    ->revised()
    ->create();
```

---

## Naming Convention

| Pattern       | Name                                    |
| ------------- | --------------------------------------- |
| Set attribute | `titled()`, `published()`, `active()`   |
| Add relation  | `withChapters()`, `withAuthor()`        |
| Post-create   | `revised()`, `verified()`, `approved()` |
| Complex setup | `withDeepHierarchy()`, `fullyLoaded()`  |

---

## Reference

- [Laravel: Eloquent Factories](https://laravel.com/docs/eloquent-factories)
- [Laravel: Database Testing](https://laravel.com/docs/database-testing)
