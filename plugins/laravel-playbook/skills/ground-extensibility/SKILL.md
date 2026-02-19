---
name: ground-extensibility
description: Extensibility patterns. Flexible code means fewer feature requests.
---

# Skill: Extensibility

> "Making code more flexible results in less maintenance."

## The Standard

- **Manager/Driver**: For services with multiple implementations. Users register custom drivers via `extend()` without touching core code.
- **Adapter/Interface**: For framework-agnostic cores. Define a finite interface; each backend implements it. The interface IS the extension point.
- **Plugin System**: For platforms hosting third-party code. A contract with `register()` and `boot()` lets plugins wire into the host.
- **Config-Driven Bindings**: Implementations specified in config, bound to interfaces in the provider. One config line swaps the class.
- **Static Callbacks**: Accept closures for targeted customization points. The package stores the closure, calls it at the right time.
- **Events**: Fire events at key moments. The listener is the user's code. Zero coupling.
- **Macroable**: Add the trait so users can extend your classes at runtime without subclassing.
- **Protected Over Private**: `protected` is an invitation. `private` is a wall. Make extension possible by default.

## The Check

Ask yourself:
- Can a user customize this without forking?
- Does the mechanism match the scale? Config for swaps, Manager for drivers, Plugin for platforms.
- Does every meaningful behavior have a seam?
- Are you adding config options when a model swap would solve it?

## Real-World Examples

See [examples.md](examples.md).
