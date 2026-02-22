---
name: craft-generator
description: Crafting generators. Artisan commands as onboarding UX.
---

# Skill: Craft Generator

> "The install command IS the first impression."

## The Standard

1. **Install Command First**: Ship a `php artisan package:install` command. It publishes config, migrations, stubs, and provider in one step. The user runs one command, not four. Horizon does this. Filament does this. Make the install command do everything `vendor:publish` would, but guided and sequenced.

1. **Stub Customization**: Ship stubs in a `stubs/` directory. Check the app's `stubs/` first, fall back to the package stub. This lets users customize generated code without forking. Pennant's `FeatureMakeCommand` does exactly this: `file_exists($customPath = $this->laravel->basePath('stubs/feature.stub'))`.

1. **Extend GeneratorCommand**: Use `Illuminate\Console\GeneratorCommand` for `make:*` commands. It handles namespace resolution, file existence checks, and stub variable replacement. Override `getStub()` for the template and `getDefaultNamespace()` for placement. The framework does the rest.

1. **Use AsCommand Attribute**: Register commands with `#[AsCommand(name: 'package:action')]`. The naming convention is `{package}:{action}` for package-specific commands, `make:{thing}` only when generating application code the user owns.

1. **Publish Tags Are Namespaced**: Every publishable asset gets a `{package}-{type}` tag. `cashier-config`, `cashier-migrations`, `cashier-views`. This lets users publish selectively. Never use generic tags like `config` or `migrations`.

1. **Migration Stubs Over Real Migrations**: Ship migrations as `.php.stub` files. The user publishes and controls when they run. This respects the developer's database workflow. Timestamps are added during publish, not at package creation time.

1. **Generator Commands Are Onboarding**: A `make:` command is not just scaffolding. It teaches structure. The generated file should include comments, sensible defaults, and the most common configuration. The stub IS documentation.

## The Anti-Patterns

| Don't                                 | Do                              | Why                                   |
|---------------------------------------|---------------------------------|---------------------------------------|
| Force migrations to run on install    | Publish as stubs                | Developers control their own database |
| Require manual `vendor:publish` steps | Ship an install command         | One command, not four                 |
| Hardcode stubs in the package         | Check app `stubs/` first        | Users customize without forking       |
| Use generic publish tags              | Namespace as `{package}-{type}` | Selective publishing                  |
| Generate empty files                  | Include comments and defaults   | Stubs teach structure                 |

## Real-World Examples

See [examples.md](examples.md).
