# Writing

Anything written down, not just replies.

`signal` holds every reply to plain English. Nothing held the written record. This does.

Voice: craftsman, always — `/output-style kernel:craftsman`. Direct, opinionated, no wasted words.

---

## The bar

Short sentences. Plain English. **What can be said in one word must not be said in two.**

Write it, then cut. **Delete any sentence that would not change what the reader does.**

State the decision. Then the one case that would prove it wrong. Stop.

| Instead of | Write |
|---|---|
| a paragraph explaining a choice | the choice, then the case that decides it |
| prose listing three things | a table |
| "we should consider whether…" | the decision |
| a heading over two sentences | the two sentences |
| "in order to", "it is worth noting" | nothing — cut it |
| a second paragraph balancing the first | the first |

---

## Structure earns its place

Use the shape the content already has — columns want a table, a layout or a flow wants a fenced
block. A shape drawn beats the paragraph describing it.

**A table cell is a few words.** Half of them here are seventeen characters and nine in ten are under
fifty. `bin/tables.sh` fails one over two hundred bytes, because that is a paragraph in a grid and no
spacing makes it readable unrendered.

**Columns are never padded.** `length` counts bytes in one locale and characters in another, so a
table aligned by one `awk` is ragged to the next — measured, and it is why the gate caps a cell
rather than lining one up.

Padding the columns is not the fix and cannot be. `length` counts bytes in one locale and characters
in another, so a table aligned by one `awk` is ragged to the next — measured, and it is why no gate
holds this.

Never a heading to decorate a paragraph. Never a section restating the one above it.

**Do not enumerate.** State the rule once and let it apply. A rule rewritten per case is the same
rule five times, and the reader stops before the case they came for. Naming today's instances dates
the file the moment one is added.

---

## Be plain about what is not true

An unverified claim, a residual risk and a known gap each get a sentence. Say which it is.

Hedging is not honesty. "May be affected" hides; "unverified on macOS" informs.

Never claim a guarantee the mechanism does not give. Name the boundary that would give it.

---

## What only the artefact can tell you

The bar above covers the rest.

| | |
|---|---|
| commit | [Commitizen](https://commitizen-tools.github.io/commitizen/) `type(scope): description`. The subject says what changed; the body says why it was wrong before |
| comment | carries a discovery, never narration. `# the fatal goes to stderr, the argument to stdout` earns its line. `# loop over the files` does not |

**A pull request answers one question: why does this change exist?** The reader already sees the diff.

Read `.github/PULL_REQUEST_TEMPLATE.md` first — `gh pr create --body` bypasses it. Close with
`Closes #N` for the issue this finishes and `Refs #N` for the rest. Never `@see`: github.com/see is a
real person, and GitHub notifies them.

**An issue holds a goal, a contract, what is deliberately not built, and a `## Done when` list.** Each
check can fail before the code exists. Name open decisions rather than guessing them.

Its list is written `- [ ]`, never `- `. A bullet nobody can tick records nothing at close, and 47 of
the first 83 lists were that shape.

