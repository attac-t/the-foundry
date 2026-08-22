# How Claude Code loads memory

Imports, path scoping, and the two ways nesting surprises you. Facts about the tool, not
judgement about your file.

### 4. Import, Don't Duplicate

```markdown
@README.md for overview.
@docs/architecture.md for structure.
```

- Paths resolve from the importing file, not cwd
- `@~/.claude/...` for home directory
- Max 5 recursive hops
- NOT evaluated inside code blocks
- First import triggers one-time approval dialog (decline = disabled forever)

### 5. Path-Scope Rules for Monorepos

```markdown
---
paths:
  - "apps/api/**/*"
---

# API Rules
- Validate input in middleware
```

Rules without `paths` always load. Rules with `paths` load conditionally.

### 6. Local Memory Quirks

`CLAUDE.local.md` only exists in one worktree. For multi-worktree, use:
```markdown
@~/.claude/my-project.md
```

### 7. Nested Memory Loads Lazily

A `CLAUDE.md` in `foo/bar/` doesn't load at startup. It loads when Claude reads files in that subtree.

---

