# Generating a memory file

### 1. Discovery

```
/memory                     # What's loaded?
Read package.json           # Commands, scripts
Read README.md              # Overview
Grep for conventions        # Patterns
```

### 2. Interview

Use `AskUserQuestion` for what you can't discover:
- Commands (build, test, lint, deploy)
- Architecture decisions
- Naming conventions
- PR/branch workflow
- What Claude should avoid

### 3. Generate

```markdown
# Project

Brief description.

## Commands

- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`

## Architecture

Key decisions. @docs/adr/ for details.

## Conventions

Naming, file structure.

## Warnings

What Claude must avoid.
```

### 4. Split (if needed)

```
.claude/rules/
├── api.md           # paths: "apps/api/**/*"
├── frontend.md      # paths: "apps/web/**/*"
└── shared.md        # No paths = always
```

---

