# The Credential Chain

Git asks each configured helper in turn and takes the first password it is given. A manager that
holds several accounts sits early in that list and answers by username, which is why the username
belongs in the remote URL.

## A blank value deletes the list

`gh auth setup-git` writes **two** values, and the first is blank:

```ini
[credential "https://github.com"]
	helper =
	helper = !gh auth git-credential
```

A blank helper resets the list. Every helper set before it is discarded — including the one the
installer put in the system config — leaving the CLI as the only door.

Nothing reports this. `credential.helper` still reads back fine, because that is a different key
from `credential.<url>.helper`, and only the second one was emptied.

## Print the origin, not the value

A value tells you what is set. The origin tells you which file to go and fix.

```bash
git config --show-origin --get-regexp '^credential\.'
```

Two lines for one key, the first blank, means the chain was reset. Remove the blank one:

```bash
val=$(git config --global --get "credential.$HOST.helper")
git config --global --unset-all "credential.$HOST.helper"
git config --global --add    "credential.$HOST.helper" "$val"
```

## An empty store looks exactly like an absent one

A freshly enabled manager holds nothing, returns nothing, and reads as though it never ran. Seed
it from the tokens the CLI already has, once per account — no browser needed:

```bash
git-credential-manager store <<EOF
protocol=https
host=$HOST
username=$USER
password=$(gh auth token --user "$USER")

EOF
```

Then prove it: point the CLI at one account and run `git credential fill` in a repo bound to the
other. The username that comes back should be the repo's, not the CLI's.
