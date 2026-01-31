---
name: craft-event-driven-model
description: Crafting Event-Driven Models. Side effects via observers.
---

# Skill: Craft Event-Driven Model

> "Models emit events. Subscribers handle consequences."

## The Standard

1. **Dispatch Domain Events**: `$dispatchesEvents` maps model events to domain events.
2. **Subscribers Handle Logic**: Calculations, notifications, logging—outside the model.
3. **Keep Models Thin**: Model changes state. Events trigger side effects.
4. **Test Events Separately**: Model tests don't test subscriber behavior.

## The Anti-Patterns

| ❌ Don't                  | ✅ Do                          | Why                        |
|--------------------------|-------------------------------|----------------------------|
| Logic in `boot()`        | Event + Subscriber            | Testable, traceable        |
| Direct method calls      | Dispatch event                | Loose coupling             |
| Fat model observers      | Focused subscribers           | Single responsibility      |
| Skip event for "simple"  | Always event for side effects | Consistency                |

## Real-World Examples

See [examples.md](examples.md).
