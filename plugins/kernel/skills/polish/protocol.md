# Running a polish

### Phase 1: Enumerate

List every file in scope. This is your manifest. No file gets skipped. Read each file **in full** — not a diff, the whole file.

### Phase 2: Seven Passes (per file)

Run all seven passes in order. Record findings per pass. Do not mix.

### Phase 3: Apply

Apply every polish. Run the project's linter on each file after editing. Run the test suite after each batch of ~5-10 related files. If tests break, revert and investigate.

### Phase 4: Self-Review

Re-read every changed file. The **vertical scan test**: open the file, scan 3 seconds, know what it does. If any file fails, polish again.

### Phase 5: Report

Produce a report at `$CLAUDE_MEMORY_DIR/reviews/{NNN}-polish-{scope}.md`.

See [examples.md](examples.md) for the report template.

## Team Mode (Large Scopes)

For large codebases (50+ files), partition by namespace or directory.

### Setup

1. **Partition** by namespace or directory boundary. ~50-70 files per agent.
2. **Spawn** one `kernel:architect` agent per partition, each receiving:
   - This entire prompt (the skill file — read it end to end)
   - Their partition assignment (directory path, file list)
   - Instruction to ground first: `Skill(kernel:ground)`, then `Skill(kernel:ground-stack)`
3. **Track** each agent maintains a file checklist. Mark each: polished, clean, or changed.

### Agent Protocol

Each agent follows Phases 1-5 independently within their partition. After completion, they produce a report at `$CLAUDE_MEMORY_DIR/reviews/{NNN}-polish-{partition}.md`.

### Lead Protocol

1. Spawn agents with explicit partition assignments
2. Wait for all agents to complete
3. Read all agent reports
4. Run the **full test suite** one final time
5. Merge into a master report at `$CLAUDE_MEMORY_DIR/reviews/{NNN}-polish-master.md`

### Cross-Partition Rule

Polish rarely crosses boundaries — renamed variables, rewritten docblocks, extracted methods are all local. If an agent changes a public method signature (which should almost never happen — that's refactoring, not polish), they notify the lead so affected agents can update imports.

## Voice

Speak like a craftsman showing their work:

- "Removed — the signature says it all."
- "Renamed — reads like English now."
- "Extracted — the method was doing two things."
- "Replaced foreach with reduce — same result, half the lines."
- "Left as-is — already clean."

No apologies. No hedging. The change is correct or you don't make it.


## Report Template

```markdown
# Polish: {Scope}

**Date:** YYYY-MM-DD
**Files in Scope:** N
**Files Polished:** N
**Files Already Clean:** N
**Tests:** All passing (N tests, N assertions)

## File Manifest

| # | File | Status | Changes |
|---|------|--------|---------|
| 1 | `path/to/File.ext` | polished | Removed 2 docblocks, renamed 1 var |
| 2 | `path/to/Other.ext` | clean | — |

## Changes by Category

### Docblocks Removed/Rewritten
| File | Method | Reason |
|------|--------|--------|

### Names Changed
| File | Before | After | Reason |
|------|--------|-------|--------|

### Methods Extracted/Shortened
| File | Method | LOC Before | LOC After | What Changed |
|------|--------|-----------|----------|--------------|

### Framework Upgrades
| File | Before | After | Feature |
|------|--------|-------|---------|

### Conditional Flattening
| File | Method | Nesting Before | Nesting After |
|------|--------|---------------|---------------|

### Test Polish
| File | Test | Change |
|------|------|--------|

## Unchanged
[Files that needed no polish — and why they were already good]
```
