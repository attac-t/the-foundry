# Ground Evidence — Examples

Six green results from one project, none measuring what its author believed. Each was quoted as
evidence before it was caught. The project is the author's, not yours — shapes to recognise, not a
record you can go and audit.

---

## The status a missing file satisfies

Seven assertions of the form *"this input must be rejected — expect a non-zero status"*. All seven
passed. The script they invoked **had not been written yet**, and command-not-found is 127.

Publish a status contract and assert exact numbers:

```
0  accepted        1  rejected        2  usage — bad input, unreadable file
```

Now 127 matches nothing and every row fails until the subject exists. **A negative assertion that
accepts a family of failures also accepts the absence of the thing it tests.**

---

## The parser that read the example

A document describing its own format contains a fenced sample of the section it also contains. The
reader took the first match and got the sample.

Seven fixtures passed throughout — every one minimal, none carrying a fence — so **a total parse
failure scored seven out of seven.** It surfaced on the first run against a real document.

Strip fenced regions before locating anything, and refuse rather than choose when two candidate
sections remain. Picking one quietly is the same defect with better manners.

---

## The count of arguments

A duplication check reported `PASS — no repeat across 36 files`. It had opened none of them: the file
list came from a query returning *tracked* files only, and everything under review was new.

The same tool skipped what it could not read and still printed the argument count — three paths, one
file read, *"across 3 files"*. Under process exhaustion it printed PASS while its own subprocesses
were dying.

Two defects, one shape: **the number described the request, not the work.**

---

## The fixtures that shared a blind spot

Seven fixtures from one template, all passing, all testing one shape.

The constructs that broke the parser in production — a fence, a repeated heading, a cross-namespace
reference — appeared in none of them, because whoever wrote the parser wrote the fixtures and both
encode the same guess about the input.

A reviewer who had written neither found two defects in an afternoon. **Where a suite comes from one
head, its coverage is that head's imagination.**

---

## The status quoted without its reason

A gate had four distinct refusals. The row asserting a refusal checked only the number, so a change
that made the tool reject for an entirely different reason left it green. Three review rounds turned
on this before anyone asked which branch had fired.

Where the reason carries the meaning, assert a fragment of the message — as a third failure branch,
not a stricter first one. **Right status, wrong reason deserves its own report.**

---

## The evidence that moved

A specification claimed: *run this against that other repository and it fails.* It did, once, and
that run was the whole justification for the work.

Two days later the same command returned success. The tool had not changed; **the other repository
had**, restructured by owners who had no idea anyone was citing it.

Copy the shape into a fixture you control. A corpus you do not own stops being evidence without
telling you, and nothing in your own results will say so.
