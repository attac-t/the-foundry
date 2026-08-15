# Guidance

Anything you want Claude to know, before you decide where to put it.

Nothing said which file, so it landed in `CLAUDE.md` — the one file that owns nothing.

---

## Which home

| Home | Holds | Loads |
|---|---|---|
| `.claude/rules/` | a constraint on how the work is done, true only here | every session, before the work starts |
| a plugin skill | a procedure — steps, commands, a template — true anywhere it is installed | when invoked, never if it is not |
| a README | what a thing is and how to work on it | when someone reads the thing it describes |
| `CLAUDE.md` | nothing. It routes to the rest | every session |

---

## The test

**Would you know to go looking for it?**

No → rule. By the time it applies you will not know it applies, so it has to already be there.

Yes → skill. The task names itself, so the steps can arrive when they are asked for.

Anything with commands in it is a skill. Its steps are only right once you are already doing the
thing, and nobody does that thing by accident.

---

## When it is both

Split it. The constraint stays in the rule, the steps move to the skill, and the rule names the
skill.

A rule that grows a numbered protocol is a skill nobody has written yet.
