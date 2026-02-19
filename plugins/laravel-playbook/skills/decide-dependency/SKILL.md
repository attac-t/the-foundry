---
name: decide-dependency
description: When to depend, suggest, vendor, or own. Dependency strategy for Laravel packages.
---

# Skill: Dependency Strategy

> "If this dependency breaks, does my package break?"

## The Decision

**Depend (require) when:**
- Core functionality depends on it
- Cherry-pick illuminate components: `illuminate/database`, `illuminate/support`
- Recommended for declarative providers: `spatie/laravel-package-tools` reduces boilerplate significantly
- Keep it minimal: 3-5 production deps for simple packages

**Suggest when:**
- Optional feature enhancement: `"league/flysystem-aws-s3-v3": "Required to use AWS S3 file storage"`
- Not needed for core functionality
- Guard in code with helpful error messages when the optional dep is missing
- Users who do not need it should not install it

**Vendor (copy) when:**
- Tiny utility that does not warrant a dependency
- Single file or function from a larger library
- The upstream is unmaintained

**Own (build yourself) when:**
- Critical path functionality -- you must control it
- Pattern across the ecosystem: Spatie owns `spatie/image`, `spatie/db-dumper`, `spatie/temporary-directory` for their critical paths
- Dependency quality or maintenance is uncertain
- You can build it better for your specific use case

**Conflict when:**
- Known-bad versions that cause silent failures
- Incompatible packages that break at runtime

## The Approaches

**Taylor's first-party approach:** Zero external dependencies. First-party packages depend only on `illuminate/*` components. Everything else is owned or suggested.

**League's agnostic approach:** Minimal dependencies, PSR interfaces, framework bridges. The core depends on nothing framework-specific. Adapters are separate packages.

**Spatie's pragmatic approach:** Cherry-pick illuminate components, own the critical path, use `spatie/laravel-package-tools` for provider boilerplate.

## The Heuristic

Ask: *"If this dependency breaks, does my package break?"*

If yes, own it or pin it tightly. If no, suggest it.

## The Quick Test

| Ask                                | Answer | Use                                   |
|------------------------------------|--------|---------------------------------------|
| Does core functionality need it?   | Yes    | Depend                                |
| Is it an optional enhancement?     | Yes    | Suggest                               |
| Is it a tiny, single-file utility? | Yes    | Vendor                                |
| Is it on the critical path?        | Yes    | Own                                   |
| Is the upstream unreliable?        | Yes    | Own or vendor                         |
| Does a known-bad version exist?    | Yes    | Conflict                              |
| Is the package framework-agnostic? | Yes    | Use PSR interfaces, bridge separately |

## Real-World Examples

See [examples.md](examples.md).
