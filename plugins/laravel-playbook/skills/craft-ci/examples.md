# CI: Examples

Patterns from production packages.

---

## The Pattern

### Workflow Skeleton

**Why?** Five workflows, zero manual gates.

```
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

Map Testbench versions to Laravel versions. Always test `prefer-lowest` -- it catches compatibility issues that `prefer-stable` hides.

```yaml
strategy:
  fail-fast: false
  matrix:
    os: [ubuntu-latest]
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
    paths:
        - src
        - config
        - database
    tmpDir: build/phpstan
    checkOctaneCompatibility: true
    checkModelProperties: true
```

### Dependabot Configuration

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
  - package-ecosystem: "composer"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
```
