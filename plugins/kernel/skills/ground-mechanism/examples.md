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

**Wrong.** A lint enumerating the words presentation code uses, run against domain code.

It cannot work, and the reason is structural rather than a matter of tuning: the vocabulary has no
last member. Every term the list holds is also a legitimate domain noun somewhere — retail sells
colour, logistics ships labels — so the list must grow to stay useful and grows false positives
faster than coverage. Measured on a real codebase, **30–60%** of its hits were wrong.

A longer list is a longer guess. `panel:craft-oracle` has the measured breakdown and what a gate
that wrong does to the people who have to read it.

**Right.** Narrow the *scope* until the set closes, and let judgment take the remainder.

- **Code**: declared identifiers under the domain namespace, checked against a per-repo allowlist.
- **Model**: everything else — including the leaks that have no vocabulary at all, like an endpoint
  shaped exactly like one screen.

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
