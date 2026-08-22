# Hitting the step

Three lines that narrow evenly. Not by a fixed number — by the same amount twice.

## The loop

1. Write the fact plainly, as one paragraph. Ignore the shape.
2. Break line one where it naturally falls. That width sets the block.
3. Break line two so the drop matches what line three will drop.
4. Land on a word boundary. Nothing is padded to reach one.
5. Close the gap: move one word across a break, or swap a word for a shorter one
   that means the same.
6. Repeat until the two steps are within three of each other.

## Why the constraint is worth keeping

Step 5 is the whole point. **Losing three characters is a search prompt** — *is
there a shorter word that means exactly this?*

Often there is, and it is the better word. You would not have looked for it. The
shape does not decorate the comment; it finds the words.

## Why not a fixed step

Because it cannot be met. Fifty-nine sentences from this repository's own rules
and READMEs, each between 90 and 200 characters:

| Asked for | Sentences that can |
|---|---|
| every step exactly three | 2 of 59 |
| steps within one | 46 of 59 |
| steps within three | 55 of 59 |
| steps within five | 59 of 59 |

Word boundaries are coarse. A rule demanding exactly three would be met by padding
in fifty-seven cases out of fifty-nine, and padding is the failure `economy` names.

**Even is the reachable strictness, and even is what makes two blocks look alike.**

## When nothing lands

Sometimes no rewording gets the steps within three. **The near miss stands.**

A fact never yields to a shape. Four sentences in fifty-nine needed that, and the
block still narrowed — it just narrowed unevenly.

## Worked

The fact, written plainly:

```
A run cannot grade green on a red base, so seven of eight gates is the expected
result and not a defect in that run's own work.
```

Broken where the words first fall — 68, 44, 18. Steps of 24 and 26:

```
# A run cannot grade green on a red base, so seven of eight gates is
# the expected result and not a defect in
# that run's own work.
```

Now with the loop. Words moved up until the drops matched:

```
# A run cannot grade green on a red base, so seven of
# eight gates is the expected result and not
# a defect in that run's own work.
```

**53, 44, 34.** Steps of 9 and 10 — within one, and the block reads as one shape
rather than three accidents.
