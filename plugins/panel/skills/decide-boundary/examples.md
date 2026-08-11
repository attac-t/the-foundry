# Examples

## One brief, four projects

> *"Let users comment on posts."*

Threading, moderation, rate limiting, and notifications — three of which have nothing to do with
comments. Plus the small domain piece that surfaced them.

| Piece                                          | Survives alone | Then                           |
|------------------------------------------------|----------------|--------------------------------|
| ordering replies under a parent                | yes            | own charter — likely a package |
| holding an item for review before it is public | yes            | own charter                    |
| refusing more than N actions per window        | yes            | own charter                    |
| a comment belongs to a post                    | no             | this charter                   |

The three that survive are not comment features. They are capabilities that any content type will
want, discovered because comments needed them first.

**This is the common case, not the exotic one.** A brief is written from the surface a user asked
for. The pieces underneath it are found by building, which is why the tells matter more than the
gate.

---

## Surviving alone is not sufficient

A tenant-scoped audit log, pulled out of the billing module because it looked general.

- **Survives alone?** Yes. Append-only log, actor, action, timestamp. Perfectly coherent.
- **Stays correct alone?** No. Inside billing it inherited the transaction that wrapped every
  balance change. Standing alone it writes outside that transaction, so a rolled-back charge now
  leaves a log entry claiming it happened.

It still runs. It still passes its own tests. The guarantee it silently depended on is not in its
own code, so nothing fails loudly.

**Ask both questions.** The first is about coherence. The second is about what the surroundings were
quietly providing.

---

## Fires more often than its host

This skill is its own example.

The decomposition judgement lived in three places: the charter gate, the verdict format, and the
author's rules. Each copy knew a fragment, and no copy pointed at the others — so the author's
version restated two of the verdict's three tells in prose, and neither half knew the other existed.

Applying the tell to itself:

> *it fires more often than its host*

Decomposition fires at charter time, authoring time, **and** verdict time. It fires more often than
any of its three hosts. That is the signature of something that wants to be extracted upward, not
split further.

**How it was caught:** a judge reading the three files against a different charter entirely. The
author had read all three many times and saw a coherent whole, because the copies were consistent
in the parts they overlapped on. Consistency between duplicates hides duplication.

---

## When splitting is the wrong call

A boundary section that fires exactly once, at the start of a longer procedure.

It reads like a standalone decision, and it would survive alone. But it is **needed once**, and the
signal is *needed twice already*. Extracting it buys nothing and costs a lookup — the reader now
leaves the procedure to learn something that only applies at step zero of that procedure.

**Over the length norm is not the same as doing two jobs.** Measure the second directly; do not
infer it from the first.
