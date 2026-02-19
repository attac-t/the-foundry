---
name: craft-deprecation
description: Crafting deprecations. Sunset gracefully, remove confidently.
---

# Skill: Craft Deprecation

> "A deprecation is a promise: you have time, and we have a plan."

## The Standard

1. **Deprecate in Minor, Remove in Major**: Introduce deprecation notices in a minor release. Remove the deprecated code in the next major. This gives consumers at least one minor version window to migrate. No surprise removals.

2. **Dual Signal — Attribute + Runtime**: Mark with `#[\Deprecated]` (PHP 8.4+) for IDE strikethrough and static analysis. Add `trigger_deprecation()` for runtime warnings on older PHP. Both signals, always.

3. **Three Files Per Deprecation**: Every deprecation PR updates CHANGELOG.md (what changed), UPGRADING.md for the current minor (how to migrate now), and UPGRADING.md for the next major (what gets removed). Symfony's discipline. Adopt it.

4. **Class Deprecation**: Create the replacement class. Extend it from the old class (or alias). Mark the old class `@deprecated`. Consumers' code keeps working. IDE shows the path forward.

5. **Method Deprecation**: Keep the old method. Proxy it to the new one. Add `#[\Deprecated]` and `trigger_deprecation()` in the body. The old method becomes a one-line redirect with a warning.

6. **Package Deprecation**: Mark abandoned on Packagist with a `suggest` pointing to the successor. Archive the GitHub repo. Write a migration guide. The package still installs — it just tells you where to go next.

7. **Automated Migration**: For structural changes (class renames, method renames), ship Rector rules or a CLI upgrade command. Filament's `filament/upgrade` is the model. Automation beats manual find-and-replace.

8. **Impact Rating**: Rate each deprecation as High / Medium / Low likelihood of impact in the upgrade guide. Developers triage — help them prioritize.

## The Anti-Patterns

| Don't                                  | Do                                              | Why                                   |
|----------------------------------------|-------------------------------------------------|---------------------------------------|
| Remove without deprecating first       | Deprecate in minor, remove in major             | Surprise removals break trust         |
| `@deprecated` docblock only            | Attribute + runtime notice + docblock           | Docblocks are invisible at runtime    |
| Deprecate without migration path       | Show the replacement in the deprecation message | A warning without a fix is just noise |
| Remove in a minor version              | Remove only in major versions                   | Semver contract. No exceptions        |
| Deprecate and remove in the same major | At least one minor version window               | Consumers need time to migrate        |
| Manual-only migration for renames      | Ship Rector rules for structural changes        | Automation scales, humans don't       |

## Real-World Examples

See [examples.md](examples.md).
