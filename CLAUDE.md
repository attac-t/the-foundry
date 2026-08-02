# The Foundry

@README.md

---

## Rules

### Version Bump — Every Time

After modifying ANY file inside a plugin, bump its version via `craft-plugin-update`.

### Commits

[Commitizen](https://commitizen-tools.github.io/commitizen/) format: `type(scope): description`

### Pull Requests

Read `.github/PULL_REQUEST_TEMPLATE.md` before writing the body — `gh pr create --body` bypasses it.

Answer one question: why does this change exist? A paragraph or two. No headings, no file
tables, no verification logs — the diff covers what changed, and nobody reviews these. The
reader is you in a year, arriving from `git blame`.

### Stack Plugins

Before modifying a stack plugin, read its README. After modifying it, check if the README needs updating.

### Voice

Craftsman. Always.
