---
name: craft-memory
description: Crafting effective CLAUDE.md files. Project memory that Claude won't ignore.
user-invocable: false
---

# Skill: Craft Memory

> "Would removing this line cause Claude to make mistakes? If not, cut it." — Anthropic

## Source of Truth

- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/best-practices

Read these first. Every time. The spec evolves.

---

## The Hierarchy

| Level        | Location                                                                                                                                              | Purpose     |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| Organization | macOS: `/Library/Application Support/ClaudeCode/CLAUDE.md`<br>Linux: `/etc/claude-code/CLAUDE.md`<br>Windows: `C:\Program Files\ClaudeCode\CLAUDE.md` | Constraints |
| User         | `~/.claude/CLAUDE.md`                                                                                                                                 | Preferences |
| Project      | `./CLAUDE.md` or `.claude/CLAUDE.md`                                                                                                                  | Context     |
| Local        | `./CLAUDE.local.md` (auto-gitignored)                                                                                                                 | Personal    |
| Rules        | `.claude/rules/*.md`                                                                                                                                  | Modular     |

Higher levels load first and take precedence.

---

## The Rules

### 1. Under 150 Lines

Bloated files get ignored. If Claude violates a rule you wrote, the file is too long.

### 2. Specific Over Vague

| Wrong                 | Right                        |
|-----------------------|------------------------------|
| Format code properly  | Use 2-space indentation      |
| Write good tests      | Tests must cover error paths |
| Follow best practices | Validate input with Zod      |

### 3. Include What Claude Can't Infer

| Include                               | Exclude                            |
|---------------------------------------|------------------------------------|
| Commands Claude can't guess           | Anything in package.json           |
| Style rules that differ from defaults | Standard language conventions      |
| Testing instructions                  | Detailed API docs (import instead) |
| Branch/PR conventions                 | Frequently changing info           |
| Architectural decisions               | File-by-file descriptions          |
| Environment quirks                    | "Write clean code"                 |
| Common gotchas                        | Tutorials                          |

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

## The Protocol

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

## Anti-Patterns

| Pattern             | Why It Fails             |
|---------------------|--------------------------|
| 150+ lines          | Gets ignored             |
| Vague rules         | Gets ignored             |
| Duplicate README    | Wastes tokens, drifts    |
| Giant monorepo file | No conditional loading   |
| Skip `/memory`      | Duplicate existing rules |

---

## See Also

[examples.md](examples.md)
