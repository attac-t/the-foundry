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
## The decisions

| Head | Code | Word | Says | Cited by |
|---|---|---|---|---|
| `active_run` | 1 | default | — | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `ask_about_each` | 1 | default | — | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `authorise` | 1 | default | this run has no charter — run \`charter derive\` first | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `check_charter` | 1 | default | this run has no charter | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `derive_charter` | 1 | default |   one is written from an origin remote and a first commit. Add whichever is missing | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `print_bootstrap` | 1 | default | — | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `read_work_item` | 1 | default | the work source holds no item [$item] | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `receive_answer` | 1 | default | — | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `refuse_unaddressed` | 1 | default | this run has read no item, so there is nowhere to address that | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `refuse_unheld_clause` | 1 | default | this run's charter holds no clause [$2], so nothing would ever read an answer about it | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `satisfied` | 1 | default | — | nobody — there is nothing to answer about. The line a person would write: **a run answers only about work it holds** |
| `accept_ancestry` | 2 |  | [$sha] is not a commit in [$tree] |  |
| `accept_ancestry` | 2 | default | accept names why [$sha] belongs here | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `accept_ancestry` | 2 | default | accept names a commit | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `add_advised` | 2 |  | the item advises no target, so name one |  |
| `add_target` | 2 | default | targets add needs a repo and a ref | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `aside` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `ask_about` | 2 | default | ask needs a stage, a clause and the question to put | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `ask_about` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `charter` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `claim` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `claim` | 2 | default | claim names an item | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `closes` | 2 |  | this run reads no item, so there is nothing to close |  |
| `code_for_judgement` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `code_for_outcome` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `commit_work` | 2 |  | nothing is staged in [$tree] |  |
| `commit_work` | 2 | default | commit names the change | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `commit_work` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `complete` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `deliver` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `deliver` | 2 | default | deliver names the change | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `evidence` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `gates` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `grant` | 2 |  | a grant names a repo |  |
| `handed` | 2 |  | a handoff names the clause, the judge, and how that judge was run |  |
| `is_kind` | 2 |  | a clause is Gate, Judged or Decided — not [$kind] |  |
| `is_one_line` | 2 |  | an event name is one line: [$event] |  |
| `is_one_line` | 2 |  | a clause is one line of text |  |
| `is_one_line` | 2 |  | a gate's name is one line: [$name] |  |
| `is_stage` | 2 |  | a question is asked at authorisation or at completion, not at [$2] |  |
| `judged` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `keep_the_brief` | 2 |  | no brief to read at [$2] |  |
| `list_runs` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `main` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `make_run` | 2 | default | new needs a title | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `make_run` | 2 |  | the clock did not answer, so this run would have no date |  |
| `merge_delivery` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `observed` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `open_workspace` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `policy` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `publish_delivery` | 2 | default | publish needs a branch and a title | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `publish_delivery` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `read_work_item` | 2 | default | read needs an item to read | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `read_work_item` | 2 | default | read names an item — its words are the source's to say, not yours | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `receive_answer` | 2 | default | receive names a stage and a clause — an answer is not something you pass | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `reconcile` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `refuse_a_judge_nobody_asked` | 2 |  | [$2] names no panel, so nothing can answer it — declare one and re-derive |  |
| `refuse_a_judge_nobody_asked` | 2 |  | [$2] is answered by [$(spaced  |  |
| `refuse_a_judge_that_is_the_worker` | 2 | invariant | a verdict comes from something that did not write what it grades | the principle *producing work grants no authority over it* |
| `refuse_a_kind_a_person_cannot_answer` | 2 |  | record a verdict instead — \`evidence verdict\` names who judged it and what they said |  |
| `refuse_a_kind_that_is_not_judged` | 2 |  | a Gate clause is answered by \`gates\`, and a Decided one by a human where the item is |  |
| `refuse_a_pinned_name` | 2 |  | record a name the charter does not pin, or run \`gates\` |  |
| `refuse_a_receipt_nobody_named` | 2 | default | receipt needs the file to read | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `refuse_a_torn_row` | 2 |  | an observation must fit one atomic write, and that one is ${#1} long |  |
| `refuse_an_unnamed_field` | 2 |  | an observation's fields are key=value, and [$pair] is not one |  |
| `refuse_unrecordable` | 2 | default | record needs a command to run — a result is not something you pass | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `refuse_unrecordable` | 2 | default | record needs a name and a command | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `release` | 2 | default | release names an item | nobody — a verb running without what it needs would act on nothing. Unlike the `usage` guards, this one says which field is missing |
| `release` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `settled` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `targets` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `verdict` | 2 |  | a verdict names the clause, the judge, the outcome, what they said, and the sha they read |  |
| `work_source` | 2 | default | — | nobody — a verb that took a shape it has no meaning for would mean two things. `usage` is what speaks here, and the site says nothing of its own |
| `die_homeless` | 3 | default | no FOUNDRY_HOME and no HOME — nowhere to put a run | nobody — a run with nowhere to write has nothing to record. The line a person would write: **a run needs a home it can write** |
| `die_unwritable` | 3 | default | could not write $1 | nobody — a run with nowhere to write has nothing to record. The line a person would write: **a run needs a home it can write** |
| `refuse_missing_resolver` | 3 | default | no gate resolver at [$(gate_resolver)] | nobody — a run with nowhere to write has nothing to record. The line a person would write: **a run needs a home it can write** |
| `refuse_missing_source` | 3 | default | no work source at [$(source_resolver)] | nobody — a run with nowhere to write has nothing to record. The line a person would write: **a run needs a home it can write** |
| `add_target` | 4 | invariant | no portable identity for [$repo] — needs a remote url, no local path, no space, no .. | the principle *Direction and evidence outlive replaceable workers*, which refuses lock-in and a worker's identity baked into the design |
| `grant` | 4 | invariant | no portable identity for [$repo] — needs a remote url, no local path, no space, no .. | the principle *Direction and evidence outlive replaceable workers*, which refuses lock-in and a worker's identity baked into the design |
| `is_usable_ref` | 4 | invariant | not a usable ref: [$ref] | the principle *Direction and evidence outlive replaceable workers*, which refuses lock-in and a worker's identity baked into the design |
| `refuse_second_ref` | 4 | invariant | start a run there, or select [$from] | the principle *Direction and evidence outlive replaceable workers*, which refuses lock-in and a worker's identity baked into the design |
| `refuse_selected_twice` | 4 | invariant | already selected: [$2] | the principle *Direction and evidence outlive replaceable workers*, which refuses lock-in and a worker's identity baked into the design |
| `add_target` | 5 |  | not authorised for this run: [$identity] — run \`policy authorize\` first |  |
| `refuse_unselectable` | 5 |  | — |  |
| `targets` | 5 |  | — |  |
| `derive_charter` | 6 | invariant | — | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `derive_charter` | 6 | invariant | refusing to drop what no longer derives: | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `derive_charter` | 6 | invariant | start a new run — one made before this rule cannot prove what it derived from | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `introduce_clause` | 6 | invariant | this clause is already $was — only derivation may make it $kind | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `refuse_collision` | 6 | invariant | — | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `refuse_moved_resolution` | 6 | invariant | — | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `refuse_wrong_repository` | 6 | invariant | run this inside [$boot], not [${here:-nowhere}] | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `check_charter` | 7 | default | — | nobody — a charter that drifted or is pinned elsewhere cannot grade this tree. The line a person would write: **a run grades only against a charter that still derives** |
| `gate_held` | 7 | default | the charter pins no command for [$name] | nobody — a charter that drifted or is pinned elsewhere cannot grade this tree. The line a person would write: **a run grades only against a charter that still derives** |
| `gate_held` | 7 | default | the charter pins a command under [$id] and names no clause for it | nobody — a charter that drifted or is pinned elsewhere cannot grade this tree. The line a person would write: **a run grades only against a charter that still derives** |
| `judge_answered` | 7 | default | the charter says nothing about how [$who] is reached for [$text] | nobody — a charter that drifted or is pinned elsewhere cannot grade this tree. The line a person would write: **a run grades only against a charter that still derives** |
| `judge_answered` | 7 | default | the charter names a judge under [$id] and no clause for it | nobody — a charter that drifted or is pinned elsewhere cannot grade this tree. The line a person would write: **a run grades only against a charter that still derives** |
| `refuse_a_judge_this_run_rewrote` | 7 | default | a judge the work can rewrite grades the work that rewrote it | nobody — a charter that drifted or is pinned elsewhere cannot grade this tree. The line a person would write: **a run grades only against a charter that still derives** |
| `refuse_an_unknown_transport` | 7 | default | [$1] is not a transport — @adapter ships one, @custom is the repository's own command | nobody — a charter that drifted or is pinned elsewhere cannot grade this tree. The line a person would write: **a run grades only against a charter that still derives** |
| `refuse_gates_from_elsewhere` | 7 | default | — | nobody — a charter that drifted or is pinned elsewhere cannot grade this tree. The line a person would write: **a run grades only against a charter that still derives** |
| `ask_pinned_judges` | 8 |  | this charter names no judge, so there is nothing here to judge |  |
| `authorise` | 8 |  | declare a gate this run's targets can be checked with, or write the requirement into an artifact derivation reads |  |
| `run_pinned_gates` | 8 |  | this charter pins no gate, so it grades nothing mechanically |  |
| `authorise` | 9 |  | clause $id grades no selected target, so it is no bar |  |
| `refuse_moved_selection` | 10 |  | — |  |
| `authorise` | 11 |  | a human owns this. Answer where the item is, naming the clause, and authorise again |  |
| `authorise` | 12 |  | re-derive, or stop the artifact declaring it |  |
| `refuse_renamed_run` | 13 |  | move it back, or start a new run — authority a human gave is not renamed with a directory |  |
| `complete` | 15 | answer | — | the runner's own header calls it an answer |
| `refuse_incomplete` | 15 | answer | — | the runner's own header calls it an answer |
| `build_and_publish` | 16 | default | [$2] is being checked out — remove [$building] if no session is | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `check_out_target` | 16 | default | no checkout here to clone [$2] from — one target, for now | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `clone_into` | 16 | default | — | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `commit_work` | 16 | default | could not commit in [$tree]: $why | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `enter_base_gates` | 16 | default | the gates this run changed could not be restored from the base | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `enter_base_gates` | 16 | default | cannot enter [$tree] | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `enter_work_tree` | 16 | default | cannot enter [$tree] | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `open_workspace` | 16 | default | [$root] holds a checkout nobody can join — its run pointer could not be written | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `publish_workspace` | 16 | default | [$2] appeared while it was being built | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `publish_workspace` | 16 | default | could not publish [$2] | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `record_base` | 16 | default | [$2] has no head to record as its base | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `record_produced` | 16 | default | committed in [$2] and could not read the sha back | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `refuse_occupied_slot` | 16 | default | [$1] is not a checkout of [$2] — remove it and open again | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `unit_work_tree` | 16 | default | — | nobody — a run that could not reach its workspace has nothing to act on. The line a person would write: **a run acts only on a workspace it holds** |
| `refuse_another_item` | 17 |  | start a new run — one item has many runs, and a second item is one of them |  |
| `refuse_unless_answered` | 17 |  | send the one it sent, or start a new run |  |
| `refuse_ungranted_delivery` | 18 | invariant | nobody said this run may deliver to [$2] — \`policy deliver-to\` is what says so | doctrine's core refusal — *producing, merging and staying silent confer none* |
| `push_workspace` | 19 |  | could not deliver [$3] to [$2]: $why |  |
| `refuse_unasked` | 20 |  | the work source could not be asked for that $2 |  |
| `ask_the_judge` | 21 | invariant | the judge could not run on this host: $said | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `ask_the_judge` | 21 | invariant | the judge was killed by signal $((answered - 128)) | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_receipt_nothing_answered` | 21 | invariant |   this is the context the runner wrote before asking, so the round did not happen | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_an_adapter_this_plugin_does_not_ship` | 21 | invariant |   looked at [$2] and nowhere else — update the plugin, or declare a custom command | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `stamp_command` | 21 | invariant | [$name] could not run on this host: $why | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `stamp_command` | 21 | invariant | [$name] was killed by signal $((result - 128)), so nothing was graded | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_unreadable_declaration` | 22 |  | the bar this repository declares cannot be read |  |
| `refuse_ungranted_merge` | 23 | invariant | nobody said this run may merge into [$2] — \`policy merge-to\` is what says so | doctrine's core refusal — *producing, merging and staying silent confer none* |
| `land_what_was_graded` | 24 | answer | this run has delivered nothing, so there is nothing to merge | the runner's own header calls it an answer |
| `refuse_a_delivery_not_open` | 24 | answer | the delivery is [$1], so there is nothing here to merge | the runner's own header calls it an answer |
| `refuse_a_moved_head` | 24 | answer | the thing merged must be the thing graded — grade again, or deliver what was graded | the runner's own header calls it an answer |
| `refuse_a_required_check_that_did_not_pass` | 24 |  | [$check] is required to land on [$1], and $(what_became_of  |  |
| `refuse_a_source_that_will_not` | 24 | answer | the source says this delivery is [$1], so it will not take it | the runner's own header calls it an answer |
| `land_what_was_graded` | 25 |  | — |  |
| `land_what_was_graded` | 25 |  | the source would not land it — a bar floor cannot read may be what refused |  |
| `source_says` | 25 |  | — |  |
| `refuse_unless_answered` | 27 |  | this work source can only be read, so nothing here can carry a $2 |  |
| `refuse_the_source_as_advice` | 28 | invariant | a human naming it with \`targets add\` still can | doctrine's core refusal — *producing, merging and staying silent confer none* |
| `claim` | 30 | answer | — | the runner's own header calls it an answer |
| `release` | 30 | answer | [$item] is not this host's to release | the runner's own header calls it an answer |
| `refuse_two_kinds` | 31 |  | an item is one kind — the inventory is short on purpose |  |
| `refuse_foreign_ancestry` | 32 |  |   a person runs \`reconcile accept <sha> <reason>\`, in a shell with no FOUNDRY_WORKER |  |
| `refuse_foreign_ancestry` | 33 | default | no base was recorded for [$2] — saw nothing, wanted a sha from \`open\` | an unmerged branch reports a foreign commit instead of refusing it, and argues that one is often deliberate. Nothing lets a repository choose — #888 |
| `refuse_foreign_ancestry` | 33 | default | [$base] is not behind [$head] in [$tree] — saw a rebuilt branch, wanted a grown one | an unmerged branch reports a foreign commit instead of refusing it, and argues that one is often deliberate. Nothing lets a repository choose — #888 |
| `refuse_foreign_ancestry` | 33 | default | [$tree] has no head to inspect — saw nothing, wanted a sha | an unmerged branch reports a foreign commit instead of refusing it, and argues that one is often deliberate. Nothing lets a repository choose — #888 |
| `refuse_foreign_ancestry` | 33 | default | could not walk [$base..$head] in [$tree] — saw a failed rev-list, wanted a range | an unmerged branch reports a foreign commit instead of refusing it, and argues that one is often deliberate. Nothing lets a repository choose — #888 |
| `refuse_unrecorded_base` | 33 |  |   this run opened before its base was recorded. Open a new one from where the work is |  |
| `refuse_self_accounting` | 34 |  | nobody is named to account for this — saw nothing, wanted FOUNDRY_WHO |  |
| `refuse_self_accounting` | 34 |  |   a person runs this in a shell with no FOUNDRY_WORKER set |  |
| `refuse_a_revision_nobody_reviewed` | 35 |  | a review of one commit is not a review of another |  |
| `refuse_a_judge_never_handed_the_bar` | 36 |  |   run.sh evidence handed <clause> <judge> is what says it was |  |
| `refuse_a_brief_nothing_recorded` | 37 | invariant |   run.sh evidence handed <clause> <judge> <how> <brief> is what records it | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_field_that_is_not_there` | 37 | invariant | $1 carries no [$said], and a receipt without one is evidence of nothing | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_freshness_about_nothing` | 37 | invariant | $1 says the context was [$fresh] and names none, so the claim is about nothing | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_freshness_that_answers_neither` | 37 | invariant | $1 says fresh [$(said_in  | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_line_that_is_not_a_receipt_line` | 37 | invariant | $1: $said | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_receipt_holding_nothing` | 37 | invariant | [$1] is there and holds nothing this can read as a receipt | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_receipt_that_is_not_there` | 37 | invariant | no receipt at [$1], and a Judged clause is answered by one | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_round_that_is_not_a_count` | 37 | invariant | $1 says round [$round], and a round is counted from one | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_round_with_no_prior` | 37 | invariant | $1 says round [$round] and names no prior verdict, so the round before it is missing | the principle *Evidence supports judgement; it does not replace it* — *a check that failed or never ran never quietly becomes a pass* |
| `refuse_a_brief_that_changed` | 38 |  | [$3] was handed brief [$was] and this receipt answers [$6] |  |
| `refuse_a_receipt_from_another_run` | 38 |  | this receipt answers for run [$2], and this run is [$(recorded_id  |  |
| `refuse_a_digest_nobody_authorised` | 40 | invariant | $1 says adapter [$ran] answered and names nothing that authorised it | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `refuse_a_pin_nobody_checked` | 40 | invariant | $1 authorises adapter [$pin] and says nothing about what ran | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `refuse_a_pin_that_is_not_a_digest` | 40 | invariant |   a tag, a version or a range moves while the repository says nothing changed | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `refuse_a_pin_the_charter_did_not_give` | 40 | invariant | [$3] is reached at [${given:-no pin at all}] and this receipt answers for [${4:-none}] | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `refuse_an_adapter_name_this_cannot_resolve` | 40 | invariant | [$1] is not an adapter name — lowercase letters, digits and hyphens, and no path in it | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `refuse_an_adapter_nobody_authorised` | 40 | invariant |   or declare a command of your own with \`@custom\` | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `refuse_an_adapter_that_moved` | 40 | invariant | $1 authorises adapter [$pin] and [$ran] is what answered | doctrine's core refusal — *authority attaches to a claim… producing, merging and staying silent confer none* |
| `say_nothing_here_can_find_it_again` | 41 | answer | so tell every later command which run: export FOUNDRY_RUN=$dir | the runner's own header calls it an answer |
