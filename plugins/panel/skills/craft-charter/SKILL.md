---
name: craft-charter
description: The goal gate. Nothing runs until the charter is approved.
---

# Skill: Craft Charter

> "If the goal isn't clear, keep questioning. Don't start."

## The Standard

- **A charter is approved by a human before any work begins.** This is the one gate a model may
  not pass on its own.
- **It states what "done" means in gradeable terms.** Without that, the adversary has nothing to
  judge against and the review degenerates into taste.
- **It names the panel.** Who judges is decided with the goal, not inferred later.
- **Refusing is not self-approval.** Anyone may refuse an unclear charter. Only the human approves.

## The Interview

**Match friction to stakes.** A rename does not earn forty questions; an authorization change does
not survive five. Ask more where the work is hard to reverse.

Drive toward three answers:

1. **What must become true?** Stated so it could be false. *"Orders over €100 ship free"* — not
   *"improve checkout"*.
2. **How would we know?** The gates. If nothing mechanical can catch a failure here, say so — that
   is a finding about the task, not a formality (see `craft-oracle`, The Coverage Rule).
3. **What is out of scope?** Explicitly. Scope drift is the most common way a run produces confident,
   unwanted work.

## Is This One Charter?

A brief often holds several projects wearing one name. *"Certificates and audits"* turned out to be
**versionable, custom-fields, meta, measurement** — four generic capabilities plus the domain work
that surfaced them. Three became reusable packages.

**The test: would this piece make sense if the request had never existed?**

| Piece | Survives alone | Then |
|-------|----------------|------|
| versioning revisions | yes | own charter — likely a package |
| issuing a certificate | no | this charter |

Two more signals: **needed twice already** in the work in front of you, and **cost asymmetry** —
extracting now is nearly free, extracting once both callers exist is not.

This gate refuses *unclear* goals. It also refuses **mis-sized** ones. Name the pieces and let the
human choose the split; never silently build four things under one name.

## The Artifact

`.claude/panel/charter.md`, committed:

```markdown
# Charter: <short name>

## Goal
One paragraph. What must become true, stated so it could be false.

## Done when
- [ ] Gate: composer test
- [ ] Gate: vendor/bin/phpstan analyse
- [ ] Judged: adversary approves with residual risks recorded

## Out of scope
Named explicitly.

## Panel
author, adversary

## Approved
<human> — YYYY-MM-DD
```

**Unapproved means unstarted.** An `Approved` line filled in by anything other than a person is the
plugin lying to itself.

## When Gates Are Weakened

If no second agent is available, the run may proceed with gate 1 self-run — **but the charter must
record it**:

```markdown
## Gates weakened
Gate 1 self-run — no adversary available. Self-assessment of this kind runs near 29% accuracy.
```

A weak gate that declares itself is honest. A self-run gate that stays silent is the failure this
plugin exists to remove.

## The Anti-Patterns

| Don't | Do | Why |
|---|---|---|
| Start while the goal is fuzzy | Keep asking | Ambiguity resolved by guessing ships wrong work |
| "Make it better" | A statement that could be false | Nothing to judge against |
| Infer the panel | Name it at approval | A model choosing its own reviewers is not review |
| Approve your own charter | A human approves | The one gate a model may not pass |
| Leave scope open | Name what's excluded | Scope drift is the common failure |
