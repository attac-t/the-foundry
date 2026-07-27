# Laravel Playbook

The package author's playbook. This plugin knows **how to ship** — skeleton to
release pipeline.

29 skills, distilled from the packages the Laravel ecosystem actually depends on.

---

## Install

```
/plugin install laravel-playbook@the-foundry
```

Pulls in [`kernel`](../kernel/README.md) automatically.

---

## Philosophy

DX is the north star. API shape, config design, error messages, docs structure —
each judged by one question: how does this feel to the developer using it?

Zero-config defaults. Progressive disclosure. Errors that teach. Code that
autocompletes.

Study the best, then surpass them.

---

## Skills

```
ground-*     Philosophy and mindset     3
craft-*      How to build              19
decide-*     When to use what           7
```

Worth knowing about:

```
ground-playbook      DX as the north star
craft-provider       Service providers — declarative core, lifecycle hooks
craft-api            Fluent builders, progressive disclosure, named constructors
craft-generator      Install commands as onboarding UX
craft-fake           The ::fake() convention, so consumers can test you
craft-exception      One class per failure mode, messages that teach
craft-test-suite     Pest + Testbench, arch tests, ::test()
craft-ci             GitHub Actions matrices, auto-fix workflows
craft-deprecation    Sunset lifecycle, trigger_deprecation(), Rector migrations
decide-agnostic      Framework-agnostic core versus Laravel-only
decide-extraction    When internal code has earned its own package
decide-positioning   Read the landscape before you build
```

The full set covers skeleton and composer.json, config design, macros, model
traits, middleware, views, README patterns, docs structure, branding, and the
release pipeline.

Browse them in [`skills/`](skills/).

---

## Sources

Patterns read out of the ecosystem's best work:

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
Tighten / Shift      Blueprint, Ziggy, Duster
Spatie               laravel-permission, medialibrary, laravel-data
```

---

## License

[MIT](../../LICENSE)
