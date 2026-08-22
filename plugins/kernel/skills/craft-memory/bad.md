# Files that get ignored, and why

## Bad

### Too Long

150+ lines = Claude ignores half.

### Too Vague

```markdown
- Format code properly
- Write good tests
```

### Duplicate

```markdown
## API Reference
[500 lines copied from docs]
```

Fix: `@docs/api.md`
