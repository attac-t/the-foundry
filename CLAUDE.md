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

### Stacked Pull Requests

Branch from the open PR you depend on, and target it. Do not branch from `main` and wait.

```bash
gh pr create --base <the-open-branch>
```

GitHub retargets the child at `main` when the parent merges.

**Stack when the second change needs the first, or when both touch
`.claude-plugin/marketplace.json`** — every plugin change does, so two branches off `main` conflict
there by construction, and `bin/versions.sh` passes on each one alone while the merge is wrong.

**Do not stack otherwise.** Independent work branches from `main`. A stack imposes a merge order,
and an order nobody needs is one somebody has to wait for.

When the parent moves, rebase the child and force-push it:

```bash
git rebase --onto <parent> <old-parent-sha> <child>
git push --force-with-lease origin <child>
```

### Stack Plugins

Before modifying a stack plugin, read its README. After modifying it, check if the README needs updating.

### Voice

Craftsman. Always.
