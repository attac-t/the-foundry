# Hitting the step

**Three bytes shorter, twice.** Line one sets the width; line two is three
bytes under it, and line three is three bytes under that.

Otwell's rule, and the reason it is worth the trouble is in step 5.

## The loop

1. Write the fact plainly, as one paragraph. Ignore the shape.
2. Break line one where it naturally falls. That width sets the block.
3. Line two must land on `len(one) - 3`, and line three on `len(one) - 6`.
4. Land on a word boundary. Nothing is padded to reach one.
5. Close the gap: move one word across a break, or swap a word for a shorter one
   that means the same.
6. If no true wording lands, **write two lines**. A three-line block that misses
   is the only failure; two lines are what rule 3 wanted anyway.

## Why the constraint is worth keeping

Step 5 is the whole point. **Losing three characters is a search prompt** — *is
there a shorter word that means exactly this?*

Often there is, and it is the better word. You would not have looked for it. The
shape does not decorate the comment; it finds the words.

## Why not a fixed step

Word boundaries are coarse. Fifty-nine sentences from this repository's own rules
and READMEs, each between 90 and 200 characters, taken as written:

| Asked for | Sentences that can |
|---|---|
| every step exactly three | 2 of 59 |
| steps within one | 46 of 59 |
| steps within three | 55 of 59 |
| steps within five | 59 of 59 |

**That measured the wrong freedom.** A sentence taken as written almost never lands.
A sentence you may reword, split at a different place, and abandon for two lines
lands often — and the whole point is the rewording.

Measured again with that freedom, across every three-line block shipped here:
**twelve of forty landed as pyramids.** The other twenty-eight became two lines,
which rule 3 preferred in the first place.

## When nothing lands

**Write two lines.** Not a near miss, and never a padded one.

A fact never yields to a shape, and a shape never yields to padding. Two lines
carry the fact and are not graded, so the only failure left is a three-line block
that misses.

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

Now with the loop. *So* became a full stop, *expected* became *normal*, and
*that run's* became *the run's* — three searches for a shorter true word:

```
# A run cannot grade green on a red base. Seven
# of eight gates is the normal result there,
# and not a defect in the run's own work.
```

**47, 44, 41.** Three and three. Nothing was padded and nothing was lost.
