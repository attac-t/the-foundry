---
name: craft-package
description: Crafting a package skeleton. The starting template for every Laravel package.
---

# Skill: Craft Package

> "A package is a promise. Its skeleton should tell you everything about what's inside before you read a single line of code."

## The Standard

1. **Directory Layout**: Every Laravel package starts with the same root structure: .editorconfig, .gitattributes, .github/, CHANGELOG.md, LICENSE.md, README.md, art/, composer.json, config/, database/migrations/, phpstan files, phpunit.xml.dist, src/, and tests/. Add resources/ for views or lang. Add docs/ when mature. Add workbench/ for Testbench-powered development environments (Taylor's first-party convention).

2. **Two Skeleton Templates**: Choose based on the package type.

   | Template                          | When                                                         | Dependencies                 |
   |-----------------------------------|--------------------------------------------------------------|------------------------------|
   | With spatie/laravel-package-tools | Most packages. Recommended. Declarative service provider.    | spatie/laravel-package-tools |
   | Without (raw ServiceProvider)     | First-party style. Zero external dependencies. Full control. | None beyond illuminate/*     |

   For framework-agnostic packages (League pattern), skip the service provider entirely. The package is pure PHP with an optional Laravel bridge.

3. **Namespace**: Vendor\{PackageName}\ maps to src/. Never Vendor\Laravel\{PackageName}\. The namespace is clean -- no framework prefix. Taylor's first-party convention uses Laravel\{Feature}\ (e.g., Laravel\Cashier\, Laravel\Scout\).

4. **composer.json**: Cherry-pick illuminate/* components. Never depend on laravel/framework. Always define test, analyse, format scripts. Register auto-discovery in extra.laravel.providers.

5. **Package Naming**:

| Convention                | Format                   | Example                   |
| ------------------------- | ------------------------ | ------------------------- |
| Community Laravel package | vendor/laravel-{feature} | spatie/laravel-permission |
| Taylor first-party        | laravel/{feature}        | laravel/cashier           |
| Framework-agnostic        | vendor/{feature}         | league/flysystem          |

6. **Auto-Discovery**: Always register in extra.laravel.providers. Register aliases only when the package exposes a facade.

7. **src/ Organization**: Three patterns. Pattern A (flat with subdirectories by concern) for most packages. Pattern B (domain-grouped) when the package has 3+ distinct domain areas. Pattern C (framework-agnostic core) when the problem is framework-independent. Don't reach for B until A feels crowded.

## The Anti-Patterns

| Don't                                    | Do                                         | Why                                               |
|------------------------------------------|--------------------------------------------|---------------------------------------------------|
| Depend on laravel/framework              | Cherry-pick illuminate/* components        | Lighter installs, broader compatibility           |
| Skip auto-discovery registration         | Always register in extra.laravel.providers | Zero-ceremony installs                            |
| Deep nesting in src/ for simple packages | Flat structure (Pattern A)                 | Complexity should match the problem               |
| Omit composer scripts                    | Always define test, analyse, format        | Consistent contributor experience                 |
| Use Vendor\Laravel\Feature\ namespace    | Use Vendor\Feature\                        | The namespace is for your code, not the framework |
| Require optional dependencies            | Use suggest with helpful messages          | Minimal dependency surface                        |
| Skip workbench/ for complex packages     | Add a Testbench dev environment            | Taylor's convention, accelerates development      |

**See also:** craft-provider (service provider patterns), craft-ci (CI pipeline setup).

## Real-World Examples

See [examples.md](examples.md).
