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

Answer one question: why does this change exist? Record it, don't argue it — cut any sentence
that would not change what the reader does. No headings, no file tables, no verification logs.
The reader is you in a year, arriving from `git blame`; they already see the diff. Close with
`Closes #N` for the issue this finishes, and `Refs #N` for anything related. Never `@see` —
[github.com/see](https://github.com/see) is a real person, and GitHub notifies them.

### Stack Plugins

Before modifying a stack plugin, read its README. After modifying it, check if the README needs updating.

### Voice

Craftsman. Always.
