# Ground Evidence — Examples

Nine green results from one project, none of them measuring what its author believed. Every fix is
in the repository's history; every one was reported as evidence before it was caught.

---

## The status that a missing file satisfies

**Wrong.** Seven assertions of the form *"this input must be rejected — expect a non-zero status"*.
All seven passed. The script they invoked **had not been written yet**; the shell was returning 127
for command-not-found, and 127 is not zero.

**Right.** Publish a status contract and assert exact numbers.

```
0  accepted        1  rejected        2  usage — bad input, unreadable file
```

Now 127 matches nothing, and every row fails until the thing exists.

**The lesson generalises past shells.** A negative assertion that accepts a family of failures also
accepts the absence of the subject.

---

## The parser that read the example instead of the section

A document describes its own format, so it contains a fenced sample of the section it also contains.
The reader took the first match and got the sample.

Seven fixtures passed throughout, because every fixture was minimal and none of them carried a fence.
**A total parse failure scored seven out of seven.** It surfaced on the first run against a real
document.

Strip fenced regions before locating anything, and refuse rather than choose when a document holds
two candidate sections — picking one quietly is the same defect with better manners.

---

## The count that was a count of arguments

A duplication check reported `PASS — no repeat across 36 files`. It had opened none of them: the
file list came from a query that returns *tracked* files only, and everything under review was new.

The same tool skipped anything it could not read and still printed the argument count — three paths,
one file read, *"across 3 files"*. Under process exhaustion it printed PASS while its own
subprocesses were dying.

Two separate defects, one shape: **the number described the request, not the work.**

Report what was consumed, and fail loudly on an input you cannot open.

---

## The fixtures that shared one blind spot

A suite of seven fixtures, all built from the same template, all passing. They tested one shape seven
times.

The constructs that broke the parser in production — a fenced block, a second heading of the same
name, a cross-namespace reference — appeared in none of them, because the author who wrote the parser
also wrote the fixtures and both encode the same guess about the input.

**A reviewer who had not written either found two defects in an afternoon.** Where a suite comes from
one head, its coverage is that head's imagination.

---

## The status quoted without its reason

A gate refused an input, and the row asserting the refusal checked only the number.

The gate had **four** distinct refusals. The row passed on any of them, so a change that made the
tool reject for an entirely different reason left every assertion green. Three consecutive review
rounds turned on this before anyone asked which branch had fired.

Where the reason carries the meaning, assert a fragment of the message. That is a third failure
branch, not a stricter version of the first: *right status, wrong reason* deserves its own report.

---

## The evidence that moved

A specification claimed: *run this against that other repository and it fails.* It did, once, and
that single run was the whole justification for the work.

Two days later the same command returned success. The tool had not changed. **The other repository
had** — restructured by its own owners, who had no idea anyone was citing it.

Copy the shape into a fixture you control. A corpus you do not own stops being evidence without
telling you, and nothing in your own results will say so.

---

## The status that belonged to another command

```bash
run-the-check | tail -1; echo $?     # this is tail's status
```

`tail` almost always succeeds. The check underneath had been failing for some time.

```bash
out=$(run-the-check); status=$?      # capture, then test
```

---

## The surface that was never enumerated

Asked whether two components were still independent, the author checked the two places that had been
under suspicion all along — declared clean, and moved on.

A third coupling had been introduced hours earlier, in the test suite: assertions that required the
other component to be installed. The claim *"they are independent"* was only ever as wide as the
search behind it, and the search was the one already done.

**List the surfaces before checking any of them, and state which surface the answer covers.**

---

## The check that was never run in anger

Five automated steps were added to a pipeline across two pieces of work. None of them had ever
executed — the account could not obtain a runner, and nothing in the configuration says so.

The pipeline definition read like enforcement for weeks. It was a list of intentions in a file that
nothing had exercised.

**An unrun check is not a passing one.** If it cannot run, say where the real enforcement lives — a
command a human runs beats a workflow nobody has seen succeed.
