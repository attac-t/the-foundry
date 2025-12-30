---
name: ground-context
description: Context budget management. Solves context exhaustion.
---

# Skill: Context Management

> "Context is RAM. Filesystem is external memory—unlimited, persistent, operable." — Manus

## When

The OS monitors context automatically. React to these thresholds.

## The Thresholds

| Usage | Action                | Why                                         |
|-------|-----------------------|---------------------------------------------|
| 60%   | Run `/compact`        | Prevent drift before it starts              |
| 80%   | Delegate to sub-agent | Preserve parent context for orchestration   |
| 90%   | Emergency compress    | Summarize aggressively, preserve objectives |

## The Protocol

1. **60% Trigger**: Compact. Preserve: objective, ADRs, failures.
2. **80% Trigger**: Spawn sub-agent for current task. Parent orchestrates.
3. **Filesystem First**: Write to files, not to context. Compression is reversible.

## The Anti-Patterns

- **Context hoarding**: Keeping everything in memory instead of files.
- **Late compaction**: Waiting until 90%+ causes objective loss.
- **Orphan sub-agents**: Delegating without clear handoff context.

## The Output

State: "Context at [X]%. Action: [compact/delegate/continue]."
