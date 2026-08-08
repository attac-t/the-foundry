# Cold-read log

Gate 2 timings, one row per run. Each reader is fresh — a resumed newcomer has already read the
document, and there is no cold read left to measure.

| date | sha | subject | locate | understand | predict | change |
|------|-----|---------|--------|------------|---------|--------|
| 2026-08-08 | `a6d8db0` | `craft-plugin-update` | 1m | 2m | 1m | 4m |

**First reading. One reading is noise** — the number that matters is the shape of the column after
three or four, and nothing here can be read as a trend yet.

Route, reader 1: locate took two greps and the top hit, no browsing. Understand needed one file and
no second. Predict was answered verbatim by the text. Change cost four minutes and three files,
because answering *"would anything tell me if I broke it"* meant reading the gates themselves.

**Test 1 landed on the heading.** `## What You Edit Is Not What Is Running` is the phrase a reader
arrives with, so the search matched the symptom rather than a term of art. That is a naming decision
working, and it should survive the next refactor.
