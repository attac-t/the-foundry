# Foundry uses Foundry

Every persisted brief and every standing item goes through Foundry's own process. That means a run,
a charter, the issues it implies, a panel, the gates and a merge.

**A gap that stops that jumps the queue.**

Done when:

- [x] Every brief on disk has been read, and its kind named — **47 of 47, 11 September.** `sh list.sh briefs` names every brief the list never mentions and exits 1 if it finds one. It finds none. It was 46 of 46 on 8 September, and the count moves as briefs arrive — so the check is the record, not the number.
- [x] Each brief that asks for work has produced the issues it implies — **held, 18 September, and the check changed.** All 48 briefs and all 65 standing items are on the forge: around 107 issues, `#782` to `#888`. `sh projected.sh` reads 48 of 48 and 65 of 65. Every brief the old check called *cited and owned by nothing* carries a ledger row, naming its issues or the issue that already owned it. **`sh list.sh opened` still says 20 cited and owned by nothing**, and it is now the wrong reader: it compares briefs to standing items, and the projection went to GitHub. The record is `PROJECTION.tsv` in the owner's directory — 48 `done`, 0 `pending`.
- [x] A gap found in the process was fixed before the work that found it carried on.
- [x] Two hosts take work from one source, and each item is paid for once — **11 September.** This machine and a container, two `uname -n` values, one directory both can see. `Lenovo` took the item; the container asked and was refused, exit 4, and the stamp still named `Lenovo`. Exclusivity under contention is `plugins/floor/tests/race.sh`: a thousand rounds, a thousand single winners, and a swap replaced by `cp` goes red.
- [ ] A second machine becomes a host from a Docker image.
- [ ] That machine grades what this one grades, and the two agree.
- [ ] The plugins are pulled after every bump, so the session runs what the tree says.

State: **renewed to 21 September 2026**, by the owner, on 14 September. In force from 7 September,
so this is the second week.

**The first week is closed and not met.** Three conditions held, one agrees by hand, three are
unmet — and two of those three want a second physical machine and nothing else. The renewal is a
decision to keep going, never a claim the week succeeded.

**What the week did.** 33 issues closed, 69 opened, 109 requests merged, 115 runs begun. **It found
more than it fixed**, and every one of the 36 extra names a gap somebody can check.

**The sharpest measure, and it is the one to move: 72 runs in 180 record anything past `run.began`.**
That is 40 per cent, measured 19 September, against 14 in 119 when this was written.

**The rise is not progress, and splitting it says why.** Floor emits five events and one is
`run.began`. The other four each need a worker to run a gate, a judge, a delivery or a read.
**Zero runs in 180 carry one of those without a worker also typing `observe`.** So all 72 were
moved by somebody deciding to type more. #595 owns it, and a charter for the fix waits on the
owner.

| Condition | Where it stands |
|---|---|
| every brief read | **46 of 46, 8 September.** Not one was an untouched task. Four are answers a model already gave, five fix work already running, two are add-ons to a run in flight, and the rest are artefacts, judgements and a spent pass |
| each asking brief has its issues | **held, 18 September.** 48 of 48 briefs and 65 of 65 items projected into issues, `#782` to `#888`. The reader is `projected.sh` against `PROJECTION.tsv`; `list.sh opened` compares briefs to standing items and cannot see work that went to the forge |
| a gap fixed first | **held four times on 8 September.** A version collision no check could see, [#598](https://github.com/attac-t/the-foundry/issues/598). The week goal with no goal record, which this file fixed. A host able to drop a claim it never held, [#607](https://github.com/attac-t/the-foundry/pull/607). And a brief's state unreadable, [#602](https://github.com/attac-t/the-foundry/issues/602). **Each was fixed before the work that found it carried on** |
| two hosts, one source | **held, 14 September.** [#303](https://github.com/attac-t/the-foundry/issues/303) closed with all seven boxes. `plugins/floor/tests/race.sh` gave **1000 rounds, 1000 single winners, 0 failed**, with both claims started before either was read. **Its reach: the claim, on the directory source.** The github adapter claims by pushing a ref and is unproven at that scale |
| a machine becomes a host | **unmet, and narrower again.** [#299](https://github.com/attac-t/the-foundry/issues/299) holds five of seven. **Linux driven 14 September** from a WSL2 shell: `sh bin/host.sh` built the image, ran as `forge`, and three gates went green inside it from a clone. **That daemon is shared with Windows**, so it proves a Linux shell, never a distribution running its own. Two boxes left: macOS, and a second machine |
| the plugins pulled | **half holds and half cannot be checked, 17 September.** The pull: the marketplace was updated from this checkout and `claude plugin update` took floor from 0.79.12 to 0.79.14. **`plugins.sh session` now exits 0 and says nothing** — the first time in days. The earlier reading blamed six kernel copies, and that was `host`, which reports and never refused. **The second half is unobservable.** Nothing inside a session can say which copy it loaded, so *the session runs what the tree says* is reachable and ungateable. [#559](https://github.com/attac-t/the-foundry/issues/559) shipped the report, never the pull, and a person still types the two commands and restarts |

**A brief is the start, never the scope.** It opens work and does not bound it.

One brief becomes several issues. Those become charters. A thing the size of a runtime earns more
than one RFC before a line is written. **A brief that produced one issue was read as a task.**

**The bar on anything written or built:** single-barrel names, early returns, one word where two
would do. `signal` owns the prose bar and `kernel:craft-sh` owns the shell.

**Judges alternate where it is merited.** Often Opus is enough, and saying so is part of the goal.

Accepted: 7 September 2026, by the repository owner, amended three times on the 8th. Recorded in
[the decision](../decisions/foundry-uses-foundry-is-the-week-goal.md), which quotes the words they
used.

Evidence: the standing list in the owner's own directory holds the day-by-day record. Sixteen
requests merged on 8 September. Each was graded as the tree it makes, not one branch at a time.
