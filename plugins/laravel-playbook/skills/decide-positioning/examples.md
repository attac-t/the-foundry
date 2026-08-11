# Package Positioning: Examples

Real-world examples from the framework and production code.

---

## Framework Examples

### The Research Protocol

**Step 1: Packagist Audit** -- For every result with 100k+ downloads:
```text
Package name / Downloads / Stars / Last commit / Open issues
Maintenance verdict: [ Active / Stale / Abandoned ]
```
Last commit > 12 months = likely abandoned. Responsive to issues but slow on PRs = opportunity.

**Step 2: DX Comparison** -- Install the top 2-3 alternatives. Actually use them.

| Criterion                      | Package A | Package B | Yours |
|--------------------------------|-----------|-----------|-------|
| Lines to first working example |           |           |       |
| Config keys required           |           |           |       |
| Error message clarity          |           |           |       |
| IDE autocompletion             |           |           |       |
| Test helpers provided          |           |           |       |

First-touch DX is the most important metric. The package that gets to "it works" fastest wins.

**Step 3: Differentiation** -- One sentence. If you cannot name it, you do not have it.

### The Positioning Statement

```text
[Package] is a [category] for Laravel that [differentiator]
unlike [alternative] which [limitation].
```
```text
Pest is a testing framework for PHP that focuses on simplicity,
unlike PHPUnit which requires verbose class-based syntax.

Filament is an admin panel for Laravel with composable components,
unlike Nova which requires a commercial license.
```
If you can't complete this template convincingly, you're not ready to build.

### Same Domain, Better DX: Pest vs PHPUnit
**Why?** Pest didn't replace PHPUnit's engine. It positioned as a DX layer on top.
```php
// PHPUnit: 8 lines
class ExampleTest extends TestCase
{
    public function test_it_works(): void
    {
        $this->assertTrue(true);
    }
}

// Pest: 3 lines
it('works', function () {
    expect(true)->toBeTrue();
});
```
Kept the engine. Better DX was undeniable, not arguable.

### Platform Play: Filament vs Nova vs Backpack

| Dimension             | Nova              | Backpack          | Filament           |
|-----------------------|-------------------|-------------------|--------------------|
| License               | Commercial        | Commercial        | MIT                |
| Components standalone | No                | No                | Yes                |
| Rendering             | Vue SPA           | Blade             | Livewire           |
| First-touch DX        | Install + license | Install + license | `composer require` |

Zero-cost entry + standalone components + Livewire alignment.

---

## Production Patterns

### Positioning Through Honest Comparison
```text
laravel-permission: "Associate users with roles and permissions" (simple)
Bouncer:            "Eloquent roles and abilities" (ability-based)
Laratrust:          "Role-based access control" (team support built-in)
```
Developers who need team-scoped permissions go to Laratrust -- and that's fine. Acknowledging alternatives builds trust.

### Positioning Through Zero Dependencies: Laravel Prompts
```php
// Symfony Console
$name = $this->ask('What is your name?');

// Laravel Prompts
$name = text(
    label: 'What is your name?',
    placeholder: 'E.g. Taylor Otwell',
    required: true,
);
```
Zero dependencies. Visual differentiation is instant. Screenshots sell it.

### Naming Rules
1. **Short** -- `laravel-permission`, not `laravel-role-based-access-control-system`
2. **Descriptive** -- Guess what it does from the name
3. **Unique on Packagist** -- Search first
4. **Lowercase, hyphenated** -- `vendor/package-name`

Use `laravel-` prefix when Laravel-specific. Omit when framework-agnostic.

### Alternative Acknowledgment
```markdown
## Alternatives

- [package-a](https://github.com/...) -- Does X well. Choose it if you need Y.
- [package-b](https://github.com/...) -- Better for Z use cases.

We built this because [honest reason].
```
Developers Google alternatives anyway. Own the narrative.

### Positioning Anti-Patterns

**"Me too" package:** Find the gap. Maybe the incumbent doesn't handle tenant-scoped roles. Build for that niche.

**Feature-list competition:** Win on DX, not features. Pest didn't have more features than PHPUnit. It had better DX.

**Invisible differentiator:** If it can't be shown in a code snippet or screenshot, it's not positioning -- it's a footnote.
