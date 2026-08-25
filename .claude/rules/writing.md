# Writing

Anything written down, not just replies.

`signal` holds every reply to plain English. Nothing held the written record. This does.

**Nothing measures it, and this file does not meet it.** Signal's scorer reads any file. Run against
all seventeen documents here — three at the root, seven plugin READMEs, seven rules — **two pass.**
Twelve warn and three block. This one warns, at 11% long words and a 29-word sentence.

```sh
awk -f plugins/signal/lib/score.awk -v words_warn=99999 -v words_block=99999     -v asks_warn=99999 < FILE
```

Signal gates its own three documents and no others. Widening that would turn fifteen red, so the
number sits here instead of a gate. **Use the scorer before you commit prose. Nothing else will.**

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

**A table cell is a few words.** Half of them here are seventeen characters, and nine in ten are under
fifty. The longest is four hundred and ninety-five. That one is a paragraph in a grid, and no amount
of spacing makes it readable unrendered.

Padding the columns is not the fix and cannot be. `length` counts bytes in one locale and characters
in another. So a table one `awk` aligns is ragged to the next, and that is why no gate holds this.

Never a heading to decorate a paragraph. Never a section restating the one above it.

**Do not enumerate.** State the rule once and let it apply. A rule rewritten per case is the same
rule five times. The reader stops before the case they came for. Naming today's instances dates
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
| pull request | read `.github/PULL_REQUEST_TEMPLATE.md` first — `gh pr create --body` bypasses it. Answer one question: why does this change exist? The reader already sees the diff. Close with `Closes #N` for the issue this finishes and `Refs #N` for the rest — never `@see`, github.com/see is a real person GitHub notifies |
| issue | goal, contract, what is deliberately not built, and a `## Done when` list of checks that can each fail before the code exists. **Written `- [ ]`, never `- `** — a bullet nobody can tick records nothing at close, and 47 of the first 83 lists were that shape. Name open decisions rather than guessing them |
| commit | [Commitizen](https://commitizen-tools.github.io/commitizen/) `type(scope): description`. The subject says what changed; the body says why it was wrong before |
| comment | carries a discovery, never narration. `# the fatal goes to stderr, the argument to stdout` earns its line. `# loop over the files` does not |
