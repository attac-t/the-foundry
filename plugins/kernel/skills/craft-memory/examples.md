# Memory: Examples

---

## Gold Standard

Dan Abramov's overreacted.io. ~40 lines.

```markdown
# CLAUDE.md

## Development Commands

- Dev: `npm run dev`
- Build: `npm run build`
- Lint: `npm run lint`

## Architecture

Static blog with Next.js App Router. Posts in `/public/[slug]/index.md`.

## Key Files

- `app/posts.js` - Post discovery
- `app/[slug]/page.js` - Post rendering

## Commit Messages

Keep it casual. Avoid listicles.

Don't embarrass me with robot speak or marketing buzzwords.
```

---

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

## Laravel

```markdown
# MyApp

Laravel 11.

## Commands

- Serve: `php artisan serve`
- Test: `php artisan test`
- Lint: `./vendor/bin/pint`

## Architecture

DDD. @docs/adr/001-structure.md

## Warnings

- No `DB::` calls
- No logic in Controllers
```

---

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
