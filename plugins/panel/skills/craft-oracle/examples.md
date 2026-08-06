# Craft Oracle — Examples

---

## The gate that voided itself

**Wrong.**

```
adversary: "I ran the test suite. Everything passes."
parent:    proceeds to approval
```

The judge is now inside the enforcement path. Nothing catches it being wrong, tired, or optimistic.

**Right.**

```
/verdict → parent runs `composer test` → exit 1
         → parent blocks, hands the output to the adversary
adversary: interprets the failure. Never asserts the outcome.
```

A judge may *explain* a failure. It may not *report* one.

---

## Same task, three stacks

The oracle contract is portable. The commands are not.

```yaml
# Laravel                        # Next.js                      # Python
gates:                           gates:                         gates:
  - name: tests                    - name: types                  - name: tests
    command: composer test             command: pnpm tsc --noEmit     command: pytest
  - name: architecture             - name: tests                  - name: types
    command: pest --testsuite=arch     command: pnpm vitest run       command: mypy .
  - name: types                    - name: build                  - name: lint
    command: phpstan analyse           command: pnpm next build       command: ruff check
```

Note the Laravel column: `pest --testsuite=arch` means **architecture has an exit code**. The thing
that sounds irreducibly human is already promoted in that stack.

---

## Where there are no oracles

A Next.js UI ticket: *"the seat picker should feel responsive when a seat is taken."*

`tsc` and `next build` say nothing about whether it feels responsive. Convening a panel here buys a
long argument about taste at triple the token cost.

**Two honest moves:**

1. **Build the oracle first.** A Playwright visual-regression snapshot and an axe a11y check are
   real gates. Now there is something to judge against.
2. **Don't convene.** Do the work solo and review it yourself. That is the correct answer more often
   than the plugin's existence suggests.

---

## Promotion, in full

**Round 1.** Adversary: *"`OrderRepository` imports `HttpClient`. A module far from IO must not
depend on one near it."* Critical. Author fixes it.

**Round 4, different feature.** Same finding, same words.

**Round 7, different feature.** Same finding again.

Three times in the same words. Promote:

```php
// tests/Arch/DependencyDirection.php
arch('domain does not depend on infrastructure')
    ->expect('App\Domain')
    ->not->toUse('App\Infrastructure');
```

```yaml
gates:
  - name: architecture
    command: vendor/bin/pest --testsuite=arch
```

That finding never costs a review round again. The judge's attention moves to something the check
cannot see.

**Recorded like this in the verdict that triggers it:**

```markdown
### Promote
Dependency direction (Domain ⇸ Infrastructure) — third occurrence, identical wording.
Candidate: Pest arch test. Author to implement as its own task.
```

---

## An open set that would not close

**Wrong.** A lint flagging presentation vocabulary in domain code: `display`, `label`, `badge`,
`formatted`, `screen`, `color`, `sortOrder`.

Measured on a real Laravel codebase: **30–60% false positives.** `page` is pagination. `label` is a
first-class object in logistics. `color` *is* the domain in retail. `sortOrder` is persisted state
whenever users define an ordering.

A gate that wrong trains people to override gates — including the ones that are right.

**Right.** Narrow the scope until the set closes:

- **Oracle**: declared identifiers under the domain namespace, against a per-repo allowlist.
- **Judgment**: everything else — including leaks with no vocabulary at all, like an endpoint shaped
  exactly like one screen.

Not every judgment is promotable. Knowing which is the skill.
