# Foundry uses Foundry

Every persisted brief and every standing item goes through Foundry's own process. That means a run,
a charter, the issues it implies, a panel, the gates and a merge.

**A gap that stops that jumps the queue.**

Done when:

- [x] Every brief on disk has been read, and its kind named — **47 of 47, 11 September.** `sh list.sh briefs` names every brief the list never mentions and exits 1 if it finds one. It finds none. It was 46 of 46 on 8 September, and the count moves as briefs arrive — so the check is the record, not the number.
- [ ] Each brief that asks for work has produced the issues it implies — **refused with a number, 11 September.** `sh list.sh opened` reads every brief on disk against the items that own one: **28 owned, 19 cited, 47 in all.** A cited brief is a row in a reading table and nothing more. #602 owns the third state, and it cannot come from that list — an item that owns a brief cites an issue 23 times out of 23, so *opened* and *answered* still read alike.
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

**The sharpest measure, and it is the one to move: 14 runs in 119 record anything past `run.began`.**
A run says work started and almost never what it proved. #595 owns it.

| Condition | Where it stands |
|---|---|
| every brief read | **46 of 46, 8 September.** Not one was an untouched task. Four are answers a model already gave, five fix work already running, two are add-ons to a run in flight, and the rest are artefacts, judgements and a spent pass |
| each asking brief has its issues | **not shown.** Reading them said what they are, never what they produced |
| a gap fixed first | **held four times on 8 September.** A version collision no check could see, [#598](https://github.com/attac-t/the-foundry/issues/598). The week goal with no goal record, which this file fixed. A host able to drop a claim it never held, [#607](https://github.com/attac-t/the-foundry/pull/607). And a brief's state unreadable, [#602](https://github.com/attac-t/the-foundry/issues/602). **Each was fixed before the work that found it carried on** |
| two hosts, one source | **held, 14 September.** [#303](https://github.com/attac-t/the-foundry/issues/303) closed with all seven boxes. `plugins/floor/tests/race.sh` gave **1000 rounds, 1000 single winners, 0 failed**, with both claims started before either was read. **Its reach: the claim, on the directory source.** The github adapter claims by pushing a ref and is unproven at that scale |
| a machine becomes a host | **unmet, and narrower again.** [#299](https://github.com/attac-t/the-foundry/issues/299) holds five of seven. **Linux driven 14 September** from a WSL2 shell: `sh bin/host.sh` built the image, ran as `forge`, and three gates went green inside it from a clone. **That daemon is shared with Windows**, so it proves a Linux shell, never a distribution running its own. Two boxes left: macOS, and a second machine |
| the plugins pulled | **the pull held, 15 September — and the check cannot say so.** Kernel went 1.27.8 to 1.28.0 in the tree, the marketplace was updated from this checkout, `claude plugin update` pulled it and the owner restarted. **1.28.0 is installed.** But `plugins.sh` exits 1, because `claude plugin list` names **six kernel copies** and the check wants exactly one equal to the tree. **Old worktrees pin the other five**, and no command clears them. So the pull is proved and the reading is not: nothing here can say which copy this session loaded. #559 shipped the report, never the pull, and only a person runs the two commands. |

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
