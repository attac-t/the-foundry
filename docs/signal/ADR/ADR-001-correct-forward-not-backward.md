# ADR-001: Correct forward, not backward

**Status**: Accepted
**Date**: 2026-08-12

## Context

signal held replies to a plain English budget with one `Stop` hook. Over budget, it returned
`decision: "block"`, and the agent wrote the reply again.

`Stop` fires after the reply is finished and streamed to the reader. Blocking does not remove it,
hide it, or replace it. It stops the turn ending and hands the agent a reason, so the agent writes a
second reply that lands beside the first. The reader gets the long answer and the short one.

That cost was documented and thought rare. It was not. Measured over 140 real final replies from
this repo:

| | |
|---|---|
| Replies scoring `block` at the shipped lines | 108 of 140 — 78% |
| Live session, 39 turns | 23 blocks |
| Live session, 12 turns | 5 blocks |
| Blocks tripping the 250-word budget | 79% |
| Median words in a blocked reply | 327 |

The cause was upstream. Nothing told the agent the budget before it wrote. There was no
`UserPromptSubmit` hook, no output style, and `skills/plain-english` loaded only if the agent
reached for it. The hook named that skill only inside a block. Every first draft was written blind,
so block-then-rewrite was the normal path rather than the exception.

Two further findings shaped the answer:

- `systemMessage` reaches the reader and never the model. The `warn` band printed the numbers to the
  one party who could not act on them, beside a reply they were already looking at.
- No hook can gate reply text before display. `MessageDisplay` is display-only, cannot block, fires
  per batch while text streams, and its replacement never reaches the transcript or the model.

## Decision

Move the work upstream, and reserve the block for the tail.

1. **A `UserPromptSubmit` hook states the budget on every prompt.** Plain stdout on that event is
   injected as context, so this is the only moment anything can act before the reply exists.
2. **The Stop hook corrects forward.** Over the warn line, it writes the numbers to a per-session
   note and prints nothing. The brief reads the note out on the next prompt and drops it. Feedback
   costs no turn and no second reply.
3. **Block only in the tail.** Block lines moved to roughly the 95th percentile of real replies —
   600 words, a 45-word sentence, 25% long words. Warn lines are unchanged, because warn is now free
   and is where the teaching happens.
4. **Every default lives in `lib/score.awk`.** The hooks pass each dial through empty when unset,
   and the brief reads the budget back out of the scorer instead of naming it.

## Consequences

- The block rate over the same corpus falls from 78% to 13%, before counting the brief's effect on
  what the agent writes in the first place.
- A reply between the warn and block lines now ships. It shipped before too — the block never
  unsent it — but the reader no longer pays a second reply to be told so.
- Feedback lands one turn late. That is the trade, and it is the right way round: a correction that
  arrives late costs nothing, where one that arrives on time costs a duplicate every time it fires.
- The brief is injected on every prompt, so it must stay short. It is two lines and it is scored
  against signal's own gate in the suite.
- signal now depends on a writable temp directory for the note. Losing it costs the forward
  correction for that turn, nothing more.

## Rejected

**Warn only, never block.** Zero duplicates, but nothing catches a reply the reader genuinely
cannot skim, where a short version has real value.

**`hookSpecificOutput.additionalContext` on Stop instead of `decision: "block"`.** Documented as the
right tool for a hook working as designed: same loop protections, and the transcript labels it
feedback rather than a hook error. Rejected on reach. `decision: "block"` is the long-standing
contract and works on every version signal installs to, and a gate that silently stops guarding on
an older client is the failure mode this plugin exists to avoid.

**One file for the note and the block marker.** They have one job each. Two obvious files beat one
clever one.

**Gate the text before display.** Not available. See `MessageDisplay` above.

## See also

- `plugins/signal/hooks/brief.sh` — the half that runs first
- `plugins/signal/hooks/signal.sh` — the half that reads what came back
- [kernel ADR-001](../../kernel/ADR/ADR-001-one-block-per-turn.md) — the same fault in kernel
