# Scoping a large repository

## Monorepo

Root `CLAUDE.md`:

```markdown
# MyApp

React frontend + Express API.

## Commands

- Install: `pnpm install`
- Dev: `pnpm dev`
- Test: `pnpm test`

## Structure

- `apps/web` - Frontend
- `apps/api` - Backend
- `packages/shared` - Types
```

`.claude/rules/api.md`:

```markdown
---
paths:
  - "apps/api/**/*"
---

# API

- Thin controllers
- `{ data, error }` response shape
- Zod validation
```

`.claude/rules/frontend.md`:

```markdown
---
paths:
  - "apps/web/**/*"
---

# Frontend

- React Query for server state
- No prop drilling past 2 levels
```

---

## Imports

```markdown
# Project

@README.md
@docs/architecture.md

## Commands

- Build: `npm run build`
```

Multi-worktree:

```markdown
@~/.claude/my-project.md
```

---

