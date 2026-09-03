---
name: craft-repo-identity
description: Binding one repository to one GitHub account when a machine holds several. Which identity signs a commit, which token pushes it, and why the CLI's account is global when everything else is per repo.
---

# Skill: Craft Repo Identity

> "One machine, many accounts. The repository says which. Nothing else gets a vote."

## When

Two GitHub accounts on one machine — work and personal, client and self. Then the global git
identity is right for one of them and silently wrong for the rest.

Silently is the word. A commit signed by the wrong account still lands. Nobody is asked.

## The Standard

Every binding is `--local`. The global one stays whatever it was, and each repo overrides it.

```bash
git config --local user.name  "Full Name"
git config --local user.email "<id>+<user>@users.noreply.github.com"
git config --local github.account "<user>"
git remote set-url origin "https://<user>@github.com/<owner>/<repo>.git"
```

Three distinct jobs, and only the first two are git's:

| Binding | Decides |
|---|---|
| `user.email` | Who the commit is attributed to |
| Username in the remote URL | Which account git asks the credential helper for |
| `github.account` | What the sync hook below reads |

Read `<id>` from `gh api user --jq .id`. The noreply address needs it; a bare
`<user>@users.noreply.github.com` will not attribute. Read `.name` too — it is often null, so set
`user.name` by hand rather than piping a blank into it.

## The Global One

Everything above is per repo. **The CLI's active account is not.** `gh auth switch` moves one
global setting, and `gh auth git-credential` answers only for whoever is active — ask it for any
other account and it returns nothing.

So `git push` fails in a repo the CLI is not currently pointed at. Not `gh push`. Plain `git`.

The username in the URL does not rescue this; it is what makes the mismatch visible instead of
letting the wrong token through. Verify a repo before trusting it:

```bash
git credential fill <<< "url=$(git config remote.origin.url)"
```

A password means the pairing holds. `could not read Password` means the CLI is on another account.

## The Sync

Because plain `git` is affected, the switch belongs on **directory change**, not on `gh`. Wrapping
`gh` leaves every `git` command uncovered. In a shell profile, read `github.account` when the
working directory changes and switch the CLI when it disagrees.

Installing Git Credential Manager removes the need — it serves several accounts at once, keyed by
the username in the URL. Until then the hook is load-bearing.

## The Anti-Patterns

| Don't | Do | Why |
|---|---|---|
| Set the identity globally per project | `--local`, in the repo | The next clone inherits the wrong one |
| Wrap `gh` to switch accounts | Sync on directory change | `git` needs the switch too, and never calls `gh` |
| Leave the remote URL bare | Put the username in it | Bare fails open — a wrong token is accepted |
| Trust a green `gh auth status` | Run `git credential fill` | Status reports the CLI, not this repo |
