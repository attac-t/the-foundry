# Mechanism — Examples

---

## The gate that voided itself

**Wrong.** An agent runs the test suite and reports back.

```
agent: "I ran the tests. They pass."
harness: proceeds
```

The model is now inside the enforcement path. It can be wrong, tired, or optimistic, and nothing
catches it. This is the single most common way a quality gate becomes decoration.

**Right.** The harness runs the command and reads the exit code.

```
harness: `vendor/bin/pest` → exit 1
harness: blocks
agent:   never consulted on the question
```

The model may *interpret* the failure. It may not *report* it.

---

## The expensive switch statement

**Wrong.** Routing by model over a closed set.

```
"Read this webhook and decide whether it is a payment, a refund, or a chargeback,
 then call the matching handler."
```

Three known branches, discriminated by a field the payload already carries. This costs tokens and
latency to be occasionally wrong about something a `match` statement is never wrong about.

**Right.**

```php
match ($payload['type']) {
    'payment.succeeded' => $this->payment($payload),
    'payment.refunded'  => $this->refund($payload),
    'charge.disputed'   => $this->chargeback($payload),
};
```

Reach for a model when the input is *"the customer emailed us about their order"* — an open set with
no discriminating field.

---

## The open set that would not close

**Wrong.** A rule requiring comments to explain *why* rather than *what*, enforced by a check.

Nothing decidable separates the two. `// retry three times` restates the loop beneath it and is
worthless; `// three retries — the upstream rate limiter forgives bursts under four` is the same
sentence carrying a fact no reader could recover from the code. A check can count words, spot a verb
lifted from the line below, flag a comment shorter than what it annotates — and each heuristic fails
on some correct comment and passes some useless one, because the property is *whether a reader
learns something*, which lives in the reader.

The vocabulary of *why* has no last member. That is the shape of an open set: not a list too short
to have been finished, but one that cannot be finished in principle.

**Right.** Narrow the *scope* until the set closes, and let judgment take the remainder.

- **Code**: a comment is *required* wherever a constant has no derivation in the file — a closed
  question, decidable from the syntax tree, no taste involved.
- **Model**: whether the comment that appears there earns its line. Judged, on review, by whoever
  has to maintain it.

---

## Promotion — judgment becoming code

A dependency-direction argument is worth having once. Won, it changes one pull request; won again
next month, it has cost two reviews and protected nothing the first win did not already establish.

The tell is the repetition, not the difficulty. Encode it and the same rule stops consuming
attention: identical every time, cheap enough to run on every commit, and it never gets tired at
five o'clock. That is the whole economics of the migration — a judgment is a recurring cost, and a
check is a fixed one.

`pest:craft-arch` is this promotion already done for one stack — architecture, which sounds
irreducibly human, has an exit code there.

**The tell that something is ready to promote:** you have written the same review comment three
times, in the same words.

---

## Demotion — code becoming judgment

A spam filter starts as three rules. Two years later it has two hundred, each traceable to one
complaint, and every new one breaks an old one.

That is not a rule engine. That is a classifier that nobody let be born.

**The tell:** rules accrete one clause per incident, and the clauses start contradicting each other.
Generalize, or hand it to a model with a labelled set — but stop adding clauses.

---

## The sandwich, in practice

Structured outputs are the canonical instance.

```
code    build the prompt from validated inputs; pin the schema
  model   choose the values
code    parse against the schema; reject on mismatch; retry or fail loudly
```

The model never decides the *shape*. It decides the *content*, inside a shape code guarantees.

---

## Where the line genuinely sits on the model's side

Not everything wants to be code. These are judgment, and forcing them into rules produces the
1980s expert-system failure:

- Naming a thing so the next reader recognizes it
- Deciding whether a spec is ambiguous
- Judging whether a refactor made the code clearer
- Assessing whether a design will be understood by someone who was not here

The check that keeps you honest: **can you write the assertion that verifies the output?** If not,
you cannot write the code that produces it either.
