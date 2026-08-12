# ADR-001: One block per turn

**Status**: Accepted
**Date**: 2026-08-12

## Context

`hooks/verify.sh` blocks the `Stop` event when `blueprint.md` still holds rows marked
`| in-progress |`. It read no stdin and checked nothing before deciding.

`stop_hook_active` is true whenever a stop hook is already driving the turn. Nothing read it, so the
hook blocked again on the continuation it had itself caused, and again after that, until Claude Code
overrode it at the eighth consecutive block (`CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`, default 8). One line
about the blueprint cost the reader up to eight replies, and the blueprint ended no closer to done.

The guard was clearly intended. `tests/install.sh` already fired the hook with
`{"stop_hook_active":false}`. The flag was in the payload the whole time and nothing had ever read
it.

Two readings of the file were possible. Its comment said "don't block, just warn", which would make
the block a bug. Its test asserted `"decision"` in the output, which makes the block the contract.
The test wins: it is the executable statement of intent, and the comment is prose that drifted.

## Decision

Keep the block. Read `stop_hook_active` through kernel's own `lib/unjson.awk` and stand down when it
is true.

The flag is set by any plugin's stop hook, not only this one, so reading it as "stand down" gives up
our block to somebody else's now and then. That trade is the right way round. A nag that arrives one
turn late costs nothing. A nag that cannot be turned off costs every turn.

## Consequences

- At most one block per turn, in place of up to eight.
- When another plugin blocks first, this hook says nothing that turn. The blueprint is still there
  next turn.
- `verify.sh` now reads stdin, so it depends on `awk` and on `lib/unjson.awk`. Both already ship and
  are covered by the preflight.

## Rejected

**Warn through `systemMessage` instead of blocking.** Costs no turn and needs no guard. Rejected
because the reason names work the agent can actually do — close the task, defer it, or write the
handoff — and a tested behaviour should not be dropped on the reviewer's taste.

**Grep the payload for the flag.** The Stop payload carries `last_assistant_message`, so the agent's
own text is in the string being searched. A reply quoting `"stop_hook_active"` would fool it. Walk
the object, do not search it.

## See also

- [signal ADR-001](../../signal/ADR/ADR-001-correct-forward-not-backward.md) — the same fault in signal
