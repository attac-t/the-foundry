---
description: Interview-driven design. Extracts requirements, writes spec, suggests new session.
argument-hint: [feature description]
---

# Design Interview

Execute the `ground-interview` skill protocol for:

"$ARGUMENTS"

Write spec to `.claude/memory/spec.md` using `templates/spec.md`.

When complete:

"**Spec complete.** Start a NEW session with:

```
Execute the spec in .claude/memory/spec.md
```"
