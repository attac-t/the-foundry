# Comments

## A Docbloc, Shaped

Both hold the same facts and only one is read.

```bash
#
# **A GitHub remote whose `gh` is missing is half of level 1.** The directory answers, correctly —
# `gh` is not in the dependency contract — but a directory has never heard of Issues, so its *nothing
# there* is the same words as an item that exists and cannot be reached.
#
# Said once, on stderr, and the exit code stays the adapter's.
#
remote_is_github && echo "source: the remote is GitHub and gh is not here" >&2
```

```bash
# A GitHub remote with no `gh` is answered by a directory, which never heard of
# Issues, so its nothing-there reads the same as an item nobody could
# reach. Said on stderr, and the exit code stays the adapter's.
remote_is_github && echo "source: the remote is GitHub and gh is not here" >&2
```

Four lines shorter for the same facts. What went: two fence lines the blank line above already drew,
a bold that shouted the sentence it sat in, and a paragraph that restated the first.

What arrived is the taper — **79, 69, 63**. The block narrows to a point, so the eye finds its end
without counting, and the third line is short enough that a fourth would look wrong. That is the
whole mechanism: the shape refuses the rambling before you write it.

**Nothing measures it.** Break where the sentence lets you. If a line will not shorten without losing
a fact, the fact stays and the block is two lines — a distinction lost to a shape is the failure
`economy` names, never the saving.

**Three is a shape, not a target.** Most facts are one sentence, and one sentence is the whole
docbloc:

```bash
# Derived, never chosen. A branch a worker names is a branch a retry can rename.
delivery_branch() { printf 'foundry/%s' "$(basename "$1")"; }
```

Padding that into three lines so it can narrow adds nothing and costs a reader two lines. The taper
is for the block that already had more to say.

## Let it breathe

```bash
main() {
    [ "$#" -eq 0 ] || { usage; exit 2; }
    refuse_without_a_repository
    refuse_without_dependencies
    refuse_without_an_author
    refuse_without_an_authority
    report_home
    report_work_source
    report_what_the_repository_carries
    say "joined."
}
```

```bash
main() {
    [ "$#" -eq 0 ] || { usage; exit 2; }

    refuse_without_a_repository
    refuse_without_dependencies
    refuse_without_an_author
    refuse_without_an_authority

    report_home
    report_work_source
    report_what_the_repository_carries
    say "joined."
}
```

Same nine calls. The second reads as three moves — check the arguments, refuse what is missing, say
what this host is — because two blank lines drew the boundaries the names only implied.

**Breathing is space, not words.** The blank line does the grouping, so no comment has to. A body
with none is held breath, and the eye scans it as one long move instead of three short ones.
