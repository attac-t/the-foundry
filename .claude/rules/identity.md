# Identity

Who the record says did the work.

---

## Never override git

**Do not pass `-c user.name` or `-c user.email`.** The checkout carries the identity, and a workspace
clone inherits it. Overriding it wrote an address the account does not own on every commit an agent
made here — GitHub linked those to nobody, and the history says a person committed when a run did.

A checkout with no identity is caught earlier: `floor`'s `join.sh` refuses and says what to run. It
is not commit time's job.

## `gh` and git are two identities

More than one account can be signed in. `gh auth switch` moves `gh` and does not move git, so a push
can succeed while the commit is attributed wrongly. It did.

**Only one of the two is loud when it breaks.** A push refused is obvious; an address nobody owns
looks exactly like a commit that worked.

## Never in an issue

No addresses, no account names. An issue is public the moment the button is pressed, and an edit does
not un-send the notification mail.

## What this is not

Not a claim that attribution is proof. `FOUNDRY_WHO` is whatever the environment says, and so is a
git address — both are records, never credentials. #156 owns making the actor real.
