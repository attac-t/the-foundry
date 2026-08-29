# A direction question is answered by Sol, at max

On 28 August 2026 the owner named which model must be asked before Foundry's direction, status or
next steps are settled.

> Anything that drives Foundry's direction, status or next steps MUST consult GPT-5.6 Sol with
> reasoning effort set to max before the conclusion is adopted, published or acted upon.
>
> This requirement is not satisfied by a generic Codex label, default reasoning effort, a
> Claude/Fable substitute, or a code review that never considered the governing question.

And what to do when it cannot be reached:

> If the required model or max setting is unavailable, record the blocker and hold the affected
> decision. Continue already-authorised work whose execution does not depend on it. Do not silently
> downgrade or substitute models.

## What it settles

Three kinds of question wait for that answer.

| | |
|---|---|
| direction | doctrine, what a goal means, priority, scope, contracts, authority, acceptance policy |
| status | progress, readiness, completion, blockers, what is left, whether a goal is met |
| next steps | choosing or reordering work, deferring a requirement, stopping or resuming |

Everything else runs on Claude, with Fable where it fits. Implementation, testing, repair, and the
calls inside a charter. **A cheaper model is not permission to lower the bar.**

Ask at a decision boundary, and batch the status with the ordered next steps. An already-answered
sequence runs without asking twice. New evidence that changes the answer needs a new one.

Record what it recommended, why, what was decided, what it read, the time, and the model and effort
the host reports. **Claim no stronger proof of identity than the host gives.**

## What it does not settle

Nothing a plugin ships. This is what *this repository* does, and no plugin contract may name a
model. A repository that installs Floor and Panel picks its own judges. `.foundry/judged` is where
it says so, and Floor reads the name without reading anything into it.

Two models agreeing creates nothing. Sol cannot grant what only the owner may.

## Nothing enforces this

**A document is not a gate.** No exit code reads this file. No check can tell a real Sol answer from
a paraphrase of one. What holds it is what holds `.foundry/practice` — the record, and whoever reads
it next.

Floor can prove a *judge* was heard. A verdict is a row in the evidence file, with a name in its own
column. It cannot prove which model wrote the row. #156 owns making an actor real.
