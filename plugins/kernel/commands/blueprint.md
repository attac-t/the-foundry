---
name: blueprint
description: Loads the project blueprint (execution ledger).
argument-hint: "[optional focus area]"
allowed-tools:
  - Read
  - Glob
  - Grep
---

# Command: Blueprint

> Load the execution ledger for this branch.

## Execute

1. Resolve memory path via `ground-topic` protocol
2. Read `$MEMORY_DIR/blueprint.md`
3. If focus provided, highlight relevant tasks
4. If no blueprint exists, prompt to create via `craft-blueprint`

## Output

Display current:
- Phase
- Active task (Current section)
- Progress summary (X/Y tasks complete)
- Any blockers or deferrals
