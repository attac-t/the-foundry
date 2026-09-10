# Identity

Who the record says did the work.

---

## Never override git

**Do not pass `-c user.name` or `-c user.email`.** The checkout carries the identity, and a workspace
clone inherits it.

Overriding it wrote an address the account does not own on every commit an agent made here — GitHub
linked those to nobody, and the history says a person committed when a run did.

**A fixture repository is the exception, and the only one.** A repo a suite makes and deletes has no
checkout behind it and no account in front of it, so it must be told who commits or `git` refuses.
Floor's suite does it. Nothing outside `tests/` may.

A checkout with no identity is caught earlier: `floor`'s `join.sh` refuses and says what to run. It
is not commit time's job.

## The forge and git are two identities

More than one account can be signed in. Switching the forge leaves git where it was, so a push can
succeed while the commit is attributed wrongly. It did.

**Only one of the two is loud when it breaks.** A push refused is obvious. An address nobody owns
looks like a commit that worked.

**So ask each of the two, apart, before the first write.** Neither answers unasked.

**A wrong author cannot be fixed.** No forge in use can change one, so the only repair is to delete
the thread. Eighty-one commits and four issues here carry the wrong account.

**Asking once is not asking.** The account changed four times in one session, none announced, each
following a clean check by under an hour. Three writes were refused by the other account's own
permissions and one landed — a finding published under a name that did not write it.

**So `.claude/hooks/identity.sh` asks at the write.** It refuses a forge write or a push when the
signed-in account is not the one this repository expects, and it names the account and the command
that fixes it. Who is expected comes from `FOUNDRY_FORGE`, else the owner in `origin`.

**It stands down where it cannot answer** — outside a repository, or when the forge will not say who
is signed in. Denying there would stop work that was fine.

It is lint. The worker holds the same account and can edit the file, and #419 owns the control that
binds.

## Never in an issue

No addresses, no account names. An issue is public the moment the button is pressed, and an edit does
not un-send the notification mail.

## What this is not

Not a claim that attribution is proof. `FOUNDRY_WHO` is whatever the environment says, and so is a
git address — both are records, never credentials. #156 owns making the actor real.
