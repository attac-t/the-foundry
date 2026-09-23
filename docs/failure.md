# When it goes wrong

Six failures that look like something else. Each names the tell and the move.

**This is for someone working on Foundry.** A stranger whose install broke wants
[README](../README.md) — one link, one form.

---

## A gate goes red

**Read the gate, never the summary.** `sh bin/gates.sh list` names all of them, one per line, and
that listing is the only count worth quoting. A number written on a page goes stale the day a gate
lands, and one did.

**A pipe answers for its last stage.** `sh bin/shell.sh | tail` reports `tail`. The gate you were
grading may have passed or died and you cannot tell.

## The audit says MOOT

**Two MOOTs, and only one is a fault.**

| It says | It means |
|---|---|
| the break did not apply | the `sed` matched no line. **Usually a rename** — the code moved and the break still names the old symbol |
| the break reported nothing | that break is **still running**. The line is written before the worker starts and replaced when it finishes |

So a steady count of the second is the worker pool being full, not that many faults.

**Test a repointed break the way the suite passes it.** Extract the line and run it through your
shell. Unescaping it by hand tests a string nothing sends, and that reads as a MOOT it is not.

## A grade dies with no summary

**The verdicts survive.** The audit writes one file per break as it finishes. The summary comes
last, so a kill takes the summary and leaves every verdict standing. Read the verdict files.

**The log's last line does not say whether it is alive.** The watcher only writes while a verdict
directory exists, so the suite phase is silent for minutes. **Read the file's modified time.**

## A run will not open

`join.sh` refuses and names the file that would have answered — a missing gate list, practice or
judged declaration. Three absences refuse. The other three print and stop nothing, by decision.

**A grade must not point at the live home.** Floor compares the runs it can see, not the ones it
made, so opening a run while a grade watches that home fails it. The failure names each run it saw
appear, so a reader can tell whose it was.

## A comment is refused

A public comment is rendered, never typed. Run `plugins/floor/bin/say.sh` with fields and post what
it printed.

**The guard reads the command line, so render and post as two separate calls.** A single call that
does both is denied whole, and its render never runs.

## A plugin bump changes nothing

**The installed copy comes from the marketplace cache, and the cache does not move on its own.** A
run that bumps a plugin keeps running the old one.

Two commands move it, and **a person runs them** — a pull, then a restart. The session keeps the
skills it loaded, so the pull alone reaches nothing.

---

## What this page is not

**Not a list of this machine's faults.** Anything true only of one host belongs in the operator's
own notes, never here.

**Not a replacement for the gate's own message.** Every refusal above names its cure. This page says
where to look when the message reads like a different problem.
