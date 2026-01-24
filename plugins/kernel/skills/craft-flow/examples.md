# Flow: Examples

Patterns for elegant ASCII flowcharts.

---

## Plugin Lifecycle

```
COLD START (SessionStart)
    │
    ├── recite        load working.md
    └── ground        load philosophy
    │
    ▼
PROMPT (UserPromptSubmit)         ← main loop
    │
    ├── anchor        echo objective
    ├── remember      prompt memory update
    └── evaluate      force skill check
    │
    ▼
RESPONSE (PostToolUse)
    │
    └── consider      prompt ADR check
    │
    ▼
CONTEXT PRESSURE (PreCompact)
    │
    └── preserve      extract to memory
```

**Flow:** Start → Prompt → Response → Repeat.

---

## Request Lifecycle

```
INTENT
    │
    ├── guard         authentication, rate limit
    └── route         match handler
    │
    ▼
HANDLER
    │
    ├── validate      input hydration
    └── dispatch      call capability
    │
    ▼
CAPABILITY
    │
    ├── guard         business rules
    ├── execute       core logic
    └── notify        events
    │
    ▼
RESPONSE
    │
    └── transform     output format
```

---

## With Annotations

```
BUILD
    │
    ├── lint          ← fast feedback
    └── typecheck     ← catch errors early
    │
    ▼
TEST
    │
    ├── unit          ← isolated
    └── integration   ← connected
    │
    ▼
DEPLOY              ← only if green
```
