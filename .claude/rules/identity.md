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

More than one account can be signed in. Switching the forge client moves the forge and leaves git
where it was, so a push can succeed while the commit is attributed wrongly. It did.

**Only one of the two is loud when it breaks.** A push refused is obvious; an address nobody owns
looks exactly like a commit that worked.

**So find out which account your writes will carry, before the first one.** Nothing announces it,
and the quiet half is the one that lasts.

**Ask each of the two, and ask them apart.** A forge client will say which identity it holds, and
so will git. Neither says it unasked, and one answer is never the other's.

**An issue filed under the wrong account cannot be moved.** No forge here offers a way to change
an author, so the only repair is to delete the thread and lose it. That makes this the cheapest
check in the file and the most expensive one to skip.

Eighty-one commits and four issues here carry the read-only account. **Two of those four were filed
by a session that never looked**, and one of them the same day this line was written.

## Never in an issue

No addresses, no account names. An issue is public the moment the button is pressed, and an edit does
not un-send the notification mail.

## What this is not

Not a claim that attribution is proof. `FOUNDRY_WHO` is whatever the environment says, and so is a
git address — both are records, never credentials. #156 owns making the actor real.
