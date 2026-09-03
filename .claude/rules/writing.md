# Writing

Anything written down, not just replies — a reader came to understand, to act or to decide.

**`signal` owns the standard — for a reply and for a file a person reads.** Four skills carry it:
`plain-english`, `economy`, `conclusion` and `stranger`. This file says only what is true here and
nowhere else.

**Nothing measures it, and this file does not meet it.** Signal's scorer reads any file. Run against
every document here — the root files, the plugin READMEs and the rules — **the ones that pass are the exception.**
Twelve warn and three block. This one warns, at 11% long words and a 29-word sentence.

```sh
awk -f plugins/signal/lib/score.awk -v words_warn=99999 -v words_block=99999     -v asks_warn=99999 < FILE
```

Signal gates its own README and every skill it ships, by glob, and nothing else. Widening it would
turn most of this repository red, so the bar sits here instead of in a gate. **Use the scorer
before you commit prose. Nothing else will.**

Voice: craftsman, always — `/output-style kernel:craftsman`. Direct, opinionated, no wasted words.

---

## The bar

Short sentences. Plain English. **One word, never two** — `signal:economy` owns that rule, and the
order it obeys. Meaning and grammar come first, and the count comes last.

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
| a pull request, an issue, a comment, a question, a closing note | five shapes, named below. `floor:brief` teaches them with examples, and the shapes hold whether or not Floor is installed |
| a `## Done when` list | **Written `- [ ]`, never `- `.** A bullet nobody can tick records nothing at close, and 47 of the first 83 lists were that shape |
| `Closes` and `Refs` | `Closes #N` for the issue this finishes, `Refs #N` for the rest. **Never `@see`** — github.com/see is a real person GitHub notifies |
| commit | [Commitizen](https://commitizen-tools.github.io/commitizen/) `type(scope): description`. The subject says what changed; the body says why it was wrong before |
| comment | carries a discovery, never narration. `# the fatal goes to stderr, the argument to stdout` earns its line. `# loop over the files` does not |

---

## The five shapes

Named here so the rule stands alone. `floor:brief` teaches the same five, with examples, wherever
Floor is installed. Neither is the other's dependency.

| Shape | Carries |
|---|---|
| work | the outcome wanted, what is deliberately not built, and a list that can each fail |
| change | what becomes true, the judgement wanted, the change, the evidence, the limits |
| update | state, delta, consequence, next. No delta, no update |
| decision | one question, the recommendation, the options and their cost, who decides |
| closure | which claims hold, which do not, and where the rest went |

**A shape is what the reader needs, never the order the work happened in.** How it was done belongs
to the run record.
