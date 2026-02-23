# CI: Examples

Patterns from the framework and production code.

---

## The Pattern

### Workflow Skeleton

**Why?** Five workflows, zero manual gates.

```text
.github/
  workflows/
    run-tests.yml
    phpstan.yml
    fix-php-code-style-issues.yml
    update-changelog.yml
    dependabot-auto-merge.yml
  dependabot.yml
  PULL_REQUEST_TEMPLATE.md

phpstan.neon.dist
phpstan-baseline.neon
```

---

## Common Scenarios

### Matrix Configuration

**Why?** Map Testbench versions to Laravel versions. Always test `prefer-lowest`.

```yaml
strategy:
  fail-fast: false
  matrix:
    php: [8.4, 8.3]
    laravel: [12.*, 11.*]
    stability: [prefer-lowest, prefer-stable]
    include:
      - laravel: 12.*
        testbench: 10.*
      - laravel: 11.*
        testbench: 9.*
```

### PHPStan Configuration

```yaml
# phpstan.neon.dist
includes:
    - phpstan-baseline.neon

parameters:
    level: 5
    paths: [src, config, database]
    checkOctaneCompatibility: true
    checkModelProperties: true
```

### Automated Code Style Fixing
**Why?** Pint fixes style on push. The CI bot commits the fix directly.

```yaml
# .github/workflows/fix-php-code-style-issues.yml
on:
  push:
    paths: ['**.php']

permissions:
  contents: write

steps:
  - uses: actions/checkout@v4
    with:
      ref: ${{ github.head_ref }}
  - uses: aglipanci/laravel-pint-action@v2
  - uses: stefanzweifel/git-auto-commit-action@v5
    with:
      commit_message: Fix styling
```

### Rector CI (Jason McCreary / Shift)
**Why?** Run Rector in CI to catch deprecated patterns before they ship.

```yaml
steps:
  - uses: actions/checkout@v4
  - uses: shivammathur/setup-php@v2
    with:
      php-version: '8.4'
  - run: composer install --no-progress
  - run: vendor/bin/rector process --dry-run
```

`--dry-run` reports what would change without modifying files. Fail the build if deprecated patterns are found.

### Dependabot Configuration

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "composer"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Dependency Audit
**Why?** `composer audit` exits non-zero when vulnerabilities exist -- CI fails automatically.

```yaml
# As a step in run-tests.yml
- name: Audit dependencies
  run: composer audit --locked
```

For scheduled scanning, add a standalone workflow triggered by `schedule` and `workflow_dispatch`.

### Coverage Thresholds
**Why?** Coverage only matters if it can't regress.

```yaml
- run: vendor/bin/pest --coverage --min=80
- run: vendor/bin/pest --type-coverage --min=100
```
