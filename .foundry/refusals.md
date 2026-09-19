# Which refusals may never soften

**Foundry installs on a repository it does not own.** The doctrine says it carries what people state
and cannot supply what nobody said. **A hard-coded refusal supplies one.**

This page names every decision floor's runner makes when it stops, and says which of three things
each one is. Nothing here is a setting. #791 owns reading the current setup and #792 owns where a
setting may live; both wait on this list.

| Word | Means |
|---|---|
| `invariant` | it may never soften. The row cites the doctrine line, principle or accepted decision that fixes it |
| `answer` | it reports what happened and refuses nothing |
| `default` | a choice somebody made once, and nobody has asked to change. The row names who might |

**A row that cites nothing is a `default`**, and says which line a person would have to write to make
it an invariant.

**Every `invariant` row is proposed until a named person accepts this list, in writing, dated.** A
model writing *doctrine fixes this* is a model asserting what doctrine says. No one has accepted it
yet.

## How a row is keyed

**One decision is one head, one code and one message.** The head is the guarded command when this
file defines it as a function, and the enclosing function otherwise — so `[`, `mkdir` and `cd` are
never heads.

**Two hundred and nine exit sites, one hundred and seventy-nine decisions.** `sh bin/refusals.sh
plugins/floor/bin/run.sh` prints the sites, and `sh bin/unnamed.sh` compares them to this
page.


## What the check cannot tell you

`sh bin/unnamed.sh` proves three things. Every decision the code makes has a row. Every row matches a
decision the code still makes. No row is blank.

**It cannot prove a word is the right word.** A row reading `default` that should read `invariant`
passes, and so does the reverse. The check counts rows; a person reads doctrine.

**So a green check here means the list is complete, never that it is correct.** The two are different
claims and only one of them has a gate.

**The citation is the only thing a reader can check.** An `invariant` row names a line somebody wrote,
and a reader who disagrees can open that line and say so. A row citing nothing is a `default` by that
rule, and the page says which line a person would have to write to change it.
## The settings, by name

**A count hides a swap.** Thirteen were reported on 18 September and fifteen were true; seventeen
stand at `24b2549`. Two of the seventeen arrived this week, on the check that reads this page.

| | |
|---|---|
| `FOUNDRY_BRIEF` `FOUNDRY_RECEIPT` | read with no fallback, which is why a grep for `${VAR:-…}` said thirteen |
| `FOUNDRY_CLAIM_TTL` `FOUNDRY_QUIET_DAYS` | a number somebody chose |
| `FOUNDRY_EPHEMERAL` | whether a run keeps what it wrote |
| `FOUNDRY_FORGE` `FOUNDRY_SOURCE` `FOUNDRY_SOURCE_DIR` | which adapter answers |
| `FOUNDRY_GATES` `FOUNDRY_JUDGED` `FOUNDRY_KEYS` | what a charter derives from |
| `FOUNDRY_HOME` `FOUNDRY_RUN` | where runs live, and which one is active |
| `FOUNDRY_REFUSALS_PAGE` `FOUNDRY_REFUSALS_READS` | **new** — `bin/unnamed.sh`, both ends settable |
| `FOUNDRY_WHO` `FOUNDRY_WORKER` | who the record says did it |

**No setting changes the condition any decision below fires on.** Several change what the run is
looking at — which adapter, which home, which file the detector reads. **That is a different thing,
and confusing the two is how a setting that softens an invariant gets built by accident.**

## What the other fifty-nine scripts hold

Measured at `24b2549`, across sixty shipped scripts — every `plugins/*/bin`, `lib`, `hooks` and
`adapters`, plus `bin/` and `.claude/hooks/`, and no `tests/`:

| | Sites | Decisions |
|---|---|---|
| `plugins/floor/bin/run.sh` | 209 | 179 |
| the other fifty-nine | 187 | 155 |
| **all sixty** | **396** | **334** |

**Twelve scripts hold two hundred and fifty-five of the decisions.** Five refuse nothing at all, and
forty-three make three or fewer. Outside the runner the weight sits in two files —
`plugins/panel/bin/verdicts.sh` and `plugins/floor/bin/adopt.sh`, sixteen each.

**So the next charter is not this one again.** Eleven more scripts reach half of what is left.
The other forty-three are a decision or two apiece, and cost more per decision than the runner
did. A page covering them needs a column this one does not have, because a head
is only unique inside its file.

## The decisions
**16 lines carry most of this page**, so a row names one by key. A line cited once stays
where it is — a key for a one-off buys indirection and saves nothing.

| Key | The line it cites |
|---|---|
| `evidence` | the principle **Evidence supports judgement; it does not replace it** — a check that failed or never ran never quietly becomes a pass |
| `refusal` | doctrine's **core refusal** — producing work grants no authority over it. Producing, merging and staying silent confer none |
| `receipt` | the principle **Evidence supports judgement** refuses *a record claiming more than a reader can check*. Doctrine's durability table says a receipt must show a named judge was asked, and answered |
| `record` | the principle **Evidence supports judgement** refuses *a record claiming more than a reader can check*. A torn row claims a thing half happened |
| `pin` | the principle **Evidence supports judgement** refuses *unknown read as pass*. Doctrine's durability table says a pin is the exact content a clause was judged against |
| `durable` | the principle **Direction and evidence outlive replaceable workers**, which refuses lock-in and a worker's identity baked into the design |
| `escalate` | the principle **Automate mechanics; escalate meaning** — Foundry never invents a costly trade-off because nobody stated one. It asks |
| `authority` | the principle **Authority is specific**, and doctrine's *What is not durable* — a record may say a named person granted something. It never confers the right |
| `header` | the runner's own header calls it an answer |
| `source` | nothing — it reports what the source did and decides nothing of its own |
| `usage` | nobody — a verb handed a shape it has no meaning for would mean two things. `usage` speaks here, and the site says nothing of its own. The line a person would write: **a verb answers only the shapes it declares** |
| `no-field` | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing. The line a person would write: **a verb acts only when every field it names is there** |
| `no-workspace` | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `nothing-held` | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `charter-drifted` | nobody — a charter that drifted or is pinned elsewhere cannot grade this tree. The line a person would write: **a run grades only against a charter that still derives** |
| `no-home` | nobody — a run with nowhere to write has nothing to record. The line a person would write: **a run needs a home it can write** |
| `one-item` | nobody yet — the person who could want it otherwise is a repository whose fix closes two issues at once. The line a person would write: **a run holds one item** |
| `our-format` | nobody — the runner writes the format it reads, so calling its own line shape doctrine is circular. A record shaped differently could be just as checkable. The line a person would write: **a record fits one line, and a field is key=value** |


| Head | Code | Word | Says | Cited by |
|---|---|---|---|---|
| `active_run` | 1 | default | — | `nothing-held` |
| `ask_about_each` | 1 | default | — | `nothing-held` |
| `authorise` | 1 | default | this run has no charter — run \`charter derive\` first | `nothing-held` |
| `check_charter` | 1 | default | this run has no charter | `nothing-held` |
| `derive_charter` | 1 | default |   one is written from an origin remote and a first commit. Add whichever is missing | `nothing-held` |
| `print_bootstrap` | 1 | default | — | `nothing-held` |
| `read_work_item` | 1 | default | the work source holds no item [$item] | `nothing-held` |
| `receive_answer` | 1 | default | — | `nothing-held` |
| `refuse_unaddressed` | 1 | default | this run has read no item, so there is nowhere to address that | `nothing-held` |
| `refuse_unheld_clause` | 1 | default | this run's charter holds no clause [$2], so nothing would ever read an answer about it | `nothing-held` |
| `satisfied` | 1 | default | — | `nothing-held` |
| `accept_ancestry` | 2 | default | [$sha] is not a commit in [$tree] | `no-field` — a sha that is not one |
| `accept_ancestry` | 2 | default | accept names why [$sha] belongs here | `no-field` |
| `accept_ancestry` | 2 | default | accept names a commit | `no-field` |
| `add_advised` | 2 | default | the item advises no target, so name one | nobody — there is nothing to act on. The line a person would write: **a run acts only on a target somebody named** |
| `add_target` | 2 | default | targets add needs a repo and a ref | `no-field` |
| `aside` | 2 | default | — | `usage` |
| `ask_about` | 2 | default | ask needs a stage, a clause and the question to put | `no-field` |
| `ask_about` | 2 | default | — | `usage` |
| `charter` | 2 | default | — | `usage` |
| `claim` | 2 | default | — | `usage` |
| `claim` | 2 | default | claim names an item | `no-field` |
| `closes` | 2 | default | this run reads no item, so there is nothing to close | `nothing-held` |
| `code_for_judgement` | 2 | default | — | `usage` |
| `code_for_outcome` | 2 | default | — | `usage` |
| `commit_work` | 2 | default | nothing is staged in [$tree] | nobody — there is nothing to act on. The line a person would write: **a run commits only work it staged** |
| `commit_work` | 2 | default | commit names the change | `no-field` |
| `commit_work` | 2 | default | — | `usage` |
| `complete` | 2 | default | — | `usage` |
| `deliver` | 2 | default | — | `usage` |
| `deliver` | 2 | default | deliver names the change | `no-field` |
| `evidence` | 2 | default | — | `usage` |
| `gates` | 2 | default | — | `usage` |
| `grant` | 2 | default | a grant names a repo | `no-field` — the unbounded grant is caught by the next guard, not this one |
| `handed` | 2 | invariant | a handoff names the clause, the judge, and how that judge was run | `receipt` |
| `is_kind` | 2 | default | a clause is Gate, Judged or Decided — not [$kind] | nobody yet — the person who could want it otherwise is a repository whose bar is proved a fourth way, and then every reader switching on three kinds would skip the fourth in silence |
| `is_one_line` | 2 | default | an event name is one line: [$event] | `our-format` |
| `is_one_line` | 2 | default | a clause is one line of text | `our-format` |
| `is_one_line` | 2 | default | a gate's name is one line: [$name] | `our-format` |
| `is_stage` | 2 | default | a question is asked at authorisation or at completion, not at [$2] | nobody yet — the person who could want it otherwise is a repository that asks its question at a third moment, and then a question asked where nothing reads it is never answered |
| `judged` | 2 | default | — | `usage` |
| `keep_the_brief` | 2 | default | no brief to read at [$2] | nobody — there is nothing to act on. The line a person would write: **a run reads only a brief it was handed** |
| `list_runs` | 2 | default | — | `usage` |
| `main` | 2 | default | — | `usage` |
| `make_run` | 2 | default | new needs a title | `no-field` |
| `make_run` | 2 | default | the clock did not answer, so this run would have no date | nobody — doctrine's durability table says a run record shows *that work began*, and never when. The line a person would write: **a run record carries the date it began** |
| `merge_delivery` | 2 | default | — | `usage` |
| `observed` | 2 | default | — | `usage` |
| `open_workspace` | 2 | default | — | `usage` |
| `policy` | 2 | default | — | `usage` |
| `publish_delivery` | 2 | default | publish needs a branch and a title | `no-field` |
| `publish_delivery` | 2 | default | — | `usage` |
| `read_work_item` | 2 | default | read needs an item to read | `no-field` |
| `read_work_item` | 2 | invariant | read names an item — its words are the source's to say, not yours | `evidence` — a worker writing the source's words |
| `receive_answer` | 2 | invariant | receive names a stage and a clause — an answer is not something you pass | `evidence` — a worker writing the answer it asked for |
| `reconcile` | 2 | default | — | `usage` |
| `refuse_a_judge_nobody_asked` | 2 | invariant | [$2] names no panel, so nothing can answer it — declare one and re-derive | `receipt` |
| `refuse_a_judge_nobody_asked` | 2 | invariant | [$2] is answered by [$(spaced  | `receipt` |
| `refuse_a_judge_that_is_the_worker` | 2 | invariant | a verdict comes from something that did not write what it grades | `refusal` |
| `refuse_a_kind_a_person_cannot_answer` | 2 | default | record a verdict instead — \`evidence verdict\` names who judged it and what they said | `usage` — the message redirects |
| `refuse_a_kind_that_is_not_judged` | 2 | default | a Gate clause is answered by \`gates\`, and a Decided one by a human where the item is | `usage` — the message redirects |
| `refuse_a_pinned_name` | 2 | invariant | record a name the charter does not pin, or run \`gates\` | `evidence` |
| `refuse_a_receipt_nobody_named` | 2 | default | receipt needs the file to read | `no-field` |
| `refuse_a_torn_row` | 2 | invariant | an observation must fit one atomic write, and that one is ${#1} long | `record` |
| `refuse_an_unnamed_field` | 2 | default | an observation's fields are key=value, and [$pair] is not one | `our-format` |
| `refuse_unrecordable` | 2 | invariant | record needs a command to run — a result is not something you pass | `evidence` — a worker writing the result of a command nothing ran |
| `refuse_unrecordable` | 2 | default | record needs a name and a command | `no-field` |
| `release` | 2 | default | release names an item | `no-field` |
| `release` | 2 | default | — | `usage` |
| `settled` | 2 | default | — | `usage` |
| `targets` | 2 | default | — | `usage` |
| `verdict` | 2 | invariant | a verdict names the clause, the judge, the outcome, what they said, and the sha they read | `receipt` |
| `work_source` | 2 | default | — | `usage` |
| `die_homeless` | 3 | default | no FOUNDRY_HOME and no HOME — nowhere to put a run | `no-home` |
| `die_unwritable` | 3 | default | could not write $1 | `no-home` |
| `refuse_missing_resolver` | 3 | default | no gate resolver at [$(gate_resolver)] | `no-home` |
| `refuse_missing_source` | 3 | default | no work source at [$(source_resolver)] | `no-home` |
| `add_target` | 4 | invariant | no portable identity for [$repo] — needs a remote url, no local path, no space, no .. | `durable` |
| `grant` | 4 | invariant | no portable identity for [$repo] — needs a remote url, no local path, no space, no .. | `durable` |
| `is_usable_ref` | 4 | default | not a usable ref: [$ref] | `no-field` — a ref format check |
| `refuse_second_ref` | 4 | invariant | start a run there, or select [$from] | `evidence` — **kept, against the second reader.** The message says the bar was derived at one ref and would grade another. That is a check that never ran on this tree, not a workspace fault |
| `refuse_selected_twice` | 4 | default | already selected: [$2] | `nothing-held` — selecting twice is a no-op |
| `add_target` | 5 | invariant | not authorised for this run: [$identity] — run \`policy authorize\` first | `refusal` |
| `refuse_unselectable` | 5 | invariant | — | `refusal` |
| `targets` | 5 | invariant | — | `refusal` |
| `derive_charter` | 6 | invariant | — | `refusal` |
| `derive_charter` | 6 | invariant | refusing to drop what no longer derives: | `refusal` |
| `derive_charter` | 6 | invariant | start a new run — one made before this rule cannot prove what it derived from | `refusal` |
| `introduce_clause` | 6 | invariant | this clause is already $was — only derivation may make it $kind | `refusal` |
| `refuse_collision` | 6 | invariant | — | `refusal` |
| `refuse_moved_resolution` | 6 | default | — | `charter-drifted` |
| `refuse_wrong_repository` | 6 | default | run this inside [$boot], not [${here:-nowhere}] | `no-workspace` — wrong directory |
| `check_charter` | 7 | default | — | `charter-drifted` |
| `gate_held` | 7 | default | the charter pins no command for [$name] | `charter-drifted` |
| `gate_held` | 7 | default | the charter pins a command under [$id] and names no clause for it | `charter-drifted` |
| `judge_answered` | 7 | default | the charter says nothing about how [$who] is reached for [$text] | `charter-drifted` |
| `judge_answered` | 7 | default | the charter names a judge under [$id] and no clause for it | `charter-drifted` |
| `refuse_a_judge_this_run_rewrote` | 7 | invariant | a judge the work can rewrite grades the work that rewrote it | `refusal` — twin of `refuse_a_judge_that_is_the_worker` |
| `refuse_an_unknown_transport` | 7 | default | [$1] is not a transport — @adapter ships one, @custom is the repository's own command | `charter-drifted` |
| `refuse_gates_from_elsewhere` | 7 | invariant | — | `evidence` — it moves, but on evidence and not the core refusal — nothing self-approves, and carrying on grades with gates that never ran |
| `ask_pinned_judges` | 8 | default | this charter names no judge, so there is nothing here to judge | nobody yet — the person who could want it otherwise is a repository whose bar is entirely mechanical, so no judge is named, and then a Judged clause would close with no receipt behind it |
| `authorise` | 8 | invariant | declare a gate this run's targets can be checked with, or write the requirement into an artifact derivation reads | `evidence` |
| `run_pinned_gates` | 8 | default | this charter pins no gate, so it grades nothing mechanically | nobody yet — the person who could want it otherwise is a repository whose bar is entirely human-judged, so no gate is pinned, and then a Gate clause would read as met with nothing having run it |
| `authorise` | 9 | invariant | clause $id grades no selected target, so it is no bar | `evidence` |
| `refuse_moved_selection` | 10 | invariant | — | `refusal` |
| `authorise` | 11 | invariant | a human owns this. Answer where the item is, naming the clause, and authorise again | `escalate` |
| `authorise` | 12 | default | re-derive, or stop the artifact declaring it | `charter-drifted` — the code's own comment calls re-deriving the remedy |
| `refuse_renamed_run` | 13 | invariant | move it back, or start a new run — authority a human gave is not renamed with a directory | `authority` |
| `complete` | 15 | answer | — | `header` |
| `refuse_incomplete` | 15 | answer | — | `header` |
| `build_and_publish` | 16 | default | [$2] is being checked out — remove [$building] if no session is | `no-workspace` |
| `check_out_target` | 16 | default | no checkout here to clone [$2] from — one target, for now | `no-workspace` |
| `clone_into` | 16 | default | — | `no-workspace` |
| `commit_work` | 16 | default | could not commit in [$tree]: $why | `no-workspace` |
| `enter_base_gates` | 16 | invariant | the gates this run changed could not be restored from the base | `refusal` — carrying on grades with gates the work rewrote |
| `enter_base_gates` | 16 | default | cannot enter [$tree] | `no-workspace` |
| `enter_work_tree` | 16 | default | cannot enter [$tree] | `no-workspace` |
| `open_workspace` | 16 | default | [$root] holds a checkout nobody can join — its run pointer could not be written | `no-workspace` |
| `publish_workspace` | 16 | default | [$2] appeared while it was being built | `no-workspace` |
| `publish_workspace` | 16 | default | could not publish [$2] | `no-workspace` |
| `record_base` | 16 | default | [$2] has no head to record as its base | `no-workspace` |
| `record_produced` | 16 | default | committed in [$2] and could not read the sha back | `no-workspace` |
| `refuse_occupied_slot` | 16 | default | [$1] is not a checkout of [$2] — remove it and open again | `no-workspace` |
| `unit_work_tree` | 16 | default | — | `no-workspace` |
| `refuse_another_item` | 17 | default | start a new run — one item has many runs, and a second item is one of them | `one-item` |
| `refuse_unless_answered` | 17 | invariant | send the one it sent, or start a new run | `refusal` |
| `refuse_ungranted_delivery` | 18 | invariant | nobody said this run may deliver to [$2] — \`policy deliver-to\` is what says so | `refusal` |
| `push_workspace` | 19 | answer | could not deliver [$3] to [$2]: $why | `source` |
| `refuse_unasked` | 20 | answer | the work source could not be asked for that $2 | `source` |
| `ask_the_judge` | 21 | invariant | the judge could not run on this host: $said | `evidence` |
| `ask_the_judge` | 21 | invariant | the judge was killed by signal $((answered - 128)) | `evidence` |
| `refuse_a_receipt_nothing_answered` | 21 | invariant |   this is the context the runner wrote before asking, so the round did not happen | `evidence` |
| `refuse_an_adapter_this_plugin_does_not_ship` | 21 | default |   looked at [$2] and nowhere else — update the plugin, or declare a custom command | `no-home` — the message already offers a custom command, so the lookup is not the policy |
| `stamp_command` | 21 | invariant | [$name] could not run on this host: $why | `evidence` |
| `stamp_command` | 21 | invariant | [$name] was killed by signal $((result - 128)), so nothing was graded | `evidence` |
| `refuse_unreadable_declaration` | 22 | invariant | the bar this repository declares cannot be read | `evidence` |
| `refuse_ungranted_merge` | 23 | invariant | nobody said this run may merge into [$2] — \`policy merge-to\` is what says so | `refusal` |
| `land_what_was_graded` | 24 | default | this run has delivered nothing, so there is nothing to merge | `nothing-held` |
| `refuse_a_delivery_not_open` | 24 | answer | the delivery is [$1], so there is nothing here to merge | `header` |
| `refuse_a_moved_head` | 24 | invariant | the thing merged must be the thing graded — grade again, or deliver what was graded | `evidence` — no source is asked, so it was never an answer |
| `refuse_a_required_check_that_did_not_pass` | 24 | invariant | [$check] is required to land on [$1], and $(what_became_of  | `evidence` |
| `refuse_a_source_that_will_not` | 24 | answer | the source says this delivery is [$1], so it will not take it | `header` |
| `land_what_was_graded` | 25 | answer | — | `source` |
| `land_what_was_graded` | 25 | answer | the source would not land it — a bar floor cannot read may be what refused | `source` |
| `source_says` | 25 | answer | — | `source` |
| `refuse_unless_answered` | 27 | answer | this work source can only be read, so nothing here can carry a $2 | `source` |
| `refuse_the_source_as_advice` | 28 | invariant | a human naming it with \`targets add\` still can | `refusal` |
| `claim` | 30 | answer | — | `header` |
| `release` | 30 | answer | [$item] is not this host's to release | `header` |
| `refuse_two_kinds` | 31 | default | an item is one kind — the inventory is short on purpose | nobody yet — the person who could want it otherwise is a repository whose work item is two kinds at once, and then a reader picking one of them answers differently each time it is asked |
| `refuse_foreign_ancestry` | 32 | invariant |   a person runs \`reconcile accept <sha> <reason>\`, in a shell with no FOUNDRY_WORKER | `refusal` — whether it stops or reports is #791's question — that a worker may not accept it is not |
| `refuse_foreign_ancestry` | 33 | invariant | no base was recorded for [$2] — saw nothing, wanted a sha from \`open\` | `evidence` — #888 disputes code 32, where the ancestry was read |
| `refuse_foreign_ancestry` | 33 | invariant | [$base] is not behind [$head] in [$tree] — saw a rebuilt branch, wanted a grown one | `evidence` — #888 disputes code 32, where the ancestry was read |
| `refuse_foreign_ancestry` | 33 | invariant | [$tree] has no head to inspect — saw nothing, wanted a sha | `evidence` — #888 disputes code 32, where the ancestry was read |
| `refuse_foreign_ancestry` | 33 | invariant | could not walk [$base..$head] in [$tree] — saw a failed rev-list, wanted a range | `evidence` — #888 disputes code 32, where the ancestry was read |
| `refuse_unrecorded_base` | 33 | invariant |   this run opened before its base was recorded. Open a new one from where the work is | `pin` |
| `refuse_self_accounting` | 34 | invariant | nobody is named to account for this — saw nothing, wanted FOUNDRY_WHO | `refusal` |
| `refuse_self_accounting` | 34 | invariant |   a person runs this in a shell with no FOUNDRY_WORKER set | `refusal` |
| `refuse_a_revision_nobody_reviewed` | 35 | invariant | a review of one commit is not a review of another | `pin` |
| `refuse_a_judge_never_handed_the_bar` | 36 | invariant |   run.sh evidence handed <clause> <judge> is what says it was | `receipt` |
| `refuse_a_brief_nothing_recorded` | 37 | invariant |   run.sh evidence handed <clause> <judge> <how> <brief> is what records it | `evidence` |
| `refuse_a_field_that_is_not_there` | 37 | invariant | $1 carries no [$said], and a receipt without one is evidence of nothing | `evidence` |
| `refuse_a_freshness_about_nothing` | 37 | invariant | $1 says the context was [$fresh] and names none, so the claim is about nothing | `evidence` |
| `refuse_a_freshness_that_answers_neither` | 37 | invariant | $1 says fresh [$(said_in  | `evidence` |
| `refuse_a_line_that_is_not_a_receipt_line` | 37 | invariant | $1: $said | `evidence` |
| `refuse_a_receipt_holding_nothing` | 37 | invariant | [$1] is there and holds nothing this can read as a receipt | `evidence` |
| `refuse_a_receipt_that_is_not_there` | 37 | invariant | no receipt at [$1], and a Judged clause is answered by one | `evidence` |
| `refuse_a_round_that_is_not_a_count` | 37 | invariant | $1 says round [$round], and a round is counted from one | `evidence` |
| `refuse_a_round_with_no_prior` | 37 | invariant | $1 says round [$round] and names no prior verdict, so the round before it is missing | `evidence` |
| `refuse_a_brief_that_changed` | 38 | invariant | [$3] was handed brief [$was] and this receipt answers [$6] | `receipt` |
| `refuse_a_receipt_from_another_run` | 38 | invariant | this receipt answers for run [$2], and this run is [$(recorded_id  | `receipt` |
| `refuse_a_digest_nobody_authorised` | 40 | invariant | $1 says adapter [$ran] answered and names nothing that authorised it | `refusal` |
| `refuse_a_pin_nobody_checked` | 40 | invariant | $1 authorises adapter [$pin] and says nothing about what ran | `refusal` |
| `refuse_a_pin_that_is_not_a_digest` | 40 | invariant |   a tag, a version or a range moves while the repository says nothing changed | `refusal` |
| `refuse_a_pin_the_charter_did_not_give` | 40 | invariant | [$3] is reached at [${given:-no pin at all}] and this receipt answers for [${4:-none}] | `refusal` |
| `refuse_an_adapter_name_this_cannot_resolve` | 40 | default | [$1] is not an adapter name — lowercase letters, digits and hyphens, and no path in it | `no-field` — a name format |
| `refuse_an_adapter_nobody_authorised` | 40 | invariant |   or declare a command of your own with \`@custom\` | `refusal` |
| `refuse_an_adapter_that_moved` | 40 | invariant | $1 authorises adapter [$pin] and [$ran] is what answered | `refusal` |
| `say_nothing_here_can_find_it_again` | 41 | answer | so tell every later command which run: export FOUNDRY_RUN=$dir | `header` |
