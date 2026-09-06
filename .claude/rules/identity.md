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

## `gh` and git are two identities

More than one account can be signed in. `gh auth switch` moves `gh` and does not move git, so a push
can succeed while the commit is attributed wrongly. It did.

**Only one of the two is loud when it breaks.** A push refused is obvious; an address nobody owns
looks exactly like a commit that worked.

**So read `gh auth status` before the first write of a session, and after any refusal.** It names
the active account in one line. Nothing else will.

**An issue filed under the wrong account cannot be moved.** GitHub offers no way to change an
author, so the only repair is to delete the thread and lose it. That makes this the cheapest check
in the file and the most expensive one to skip.

Eighty-one commits and four issues here carry the read-only account. **Two of those four were filed
by a session that never looked**, and one of them the same day this line was written.

## Never in an issue

No addresses, no account names. An issue is public the moment the button is pressed, and an edit does
not un-send the notification mail.

## What this is not

Not a claim that attribution is proof. `FOUNDRY_WHO` is whatever the environment says, and so is a
git address — both are records, never credentials. #156 owns making the actor real.
