# Laravel Playbook

The package author's playbook. Ecosystem-wide patterns for crafting, shipping, and sustaining pinnacle Laravel packages.

This plugin knows **how to build packages** — from skeleton to release pipeline. The kernel knows how to think. `laravel-ddd` knows how to code Laravel. This knows how to ship Laravel packages that developers love.

---

## Philosophy

DX is the north star. Every decision — API shape, config design, error messages, documentation structure — is evaluated through one lens: how does the developer experience this?

Zero-config defaults. Progressive disclosure. Errors that teach. Code that autocompletes.

Study the best. Then surpass them.

---

## What You Get

```
Package skeleton        Directory layout, composer.json, auto-discovery
Service providers       Declarative providers, lifecycle hooks, bindings
Config design           Self-documenting, env() toggles, zero-config defaults
API design              Fluent builders, progressive disclosure, named constructors
Generators              Install commands, stub publishing, make: commands
Macros                  Macroable, mixins, runtime extension
Fakes                   ::fake() convention for testable package interactions
Exception hierarchy     Contextual messages, one class per failure mode
Extension points        Manager/driver, adapters, plugins, config binding, events
README patterns         Benefit-first H1, badge trio, show code immediately
Documentation           docs/ structure, upgrade guides, progressive depth
Model traits            Boot/initialize conventions, concerns decomposition
Testing setup           Pest + Testbench, arch tests, ::fake(), ::test()
CI/CD pipeline          GitHub Actions workflows, matrix testing, auto-fix
Branding                Package identity, social cards, badge trio, first impressions
Deprecation             Sunset lifecycle, trigger_deprecation(), Rector migration
Middleware              Route middleware, conditional registration, parameter parsing
Views                   Blade components, view publishing, render hooks
Extraction workflow     Identifying extractable code, competitive analysis, shipping
Release pipeline        GitHub releases, auto-changelog, Packagist auto-publish
```

---

## Skills

29 skills. Three types.

```
ground-*     Philosophy and mindset (3 skills)
craft-*      How to build (19 skills)
decide-*     When to use what (7 skills)
```

### Highlights

```
ground-playbook      Core philosophy — DX as the north star
craft-provider       Service providers — three approaches, declarative core
craft-api            API design — fluent builders, progressive disclosure
craft-generator      Generators — install commands as onboarding UX
craft-fake           Fakes — ::fake() convention for testable packages
craft-test-suite     Testing — Pest, Testbench, arch tests, ::test()
decide-agnostic      Framework-agnostic core vs Laravel-only
decide-extraction    Extracting internal code to a standalone package
decide-positioning   Evaluating the landscape before building
```

Run `/skills laravel-playbook` to see all.

---

## Sources

Patterns distilled from the Laravel ecosystem's best authors:

```
Taylor Otwell        Cashier, Sanctum, Scout, Horizon, Pennant, Pulse
Nuno Maduro          Pest, Collision, Termwind, Pint, Laravel Prompts
Dan Harrin           Filament panels, Forms, Tables, Notifications
Frank de Jonge       Flysystem, EventSauce, league/csv
Caleb Porzio         Livewire, Alpine.js, Flux
Jess Archer          Laravel Prompts, Laravel core
Barry vd. Heuvel     Debugbar, IDE Helper
Tim MacDonald        callable-fake, log-fake, has-parameters
Jason McCreary       Laravel Shift, rector-laravel
Marcel Pociot        BeyondCode, package auto-discovery
Tighten / Shift      Laravel Shift, Blueprint, Ziggy, Duster
Spatie               laravel-permission, medialibrary, laravel-data, and more
```

---

## Installation

**Useful alone.** It reads better beside `kernel`, which carries the thinking patterns its skills
assume — so the line below installs both. Neither needs the other to load.

```
/plugin marketplace add attac-t/the-foundry
/plugin install kernel@the-foundry
/plugin install laravel-playbook@the-foundry
```

---

## License

MIT
