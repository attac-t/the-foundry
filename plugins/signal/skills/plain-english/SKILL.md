---
name: plain-english
description: Say it so a ten-year-old gets it on the first read. Short words, short sentences, answer first. Judged against Simplified Technical English.
---

# Skill: Plain English

> "If they have to read it twice, you wrote it once too fast."

## When

The hook blocked your reply. Or you are about to write one.

## The bar

A ten-year-old reads it once and knows what to do.

That is not a nice goal. It is the gate. People now skim ten agent chats at a time. When a reply
does not land on the first read, they do not read it again. They type "continue" and hope.

So a reply that needs a second read has failed, even when every word in it is true.

## Where the bar comes from

Two standards already settled this. Read them rather than guessing.

**[ASD-STE100 Simplified Technical English](https://www.asd-ste100.org/)** — free to download. Built
so an aircraft engineer with weak English can read a repair step and get it right the first time.
It has 53 writing rules and a dictionary of about 900 approved words, each with one meaning and one
part of speech. It also lists about 1200 words you may not use, each with a plainer one to use
instead.

The rules that matter most here:

- One meaning per word. Pick a word and keep using that same word.
- Active voice. Name who does the thing.
- Simple tenses. Not "will have been able to".
- One instruction per sentence.
- No dropped words. "The file open" is not shorter, it is broken.
- No noun stack over three words. "hook input JSON parse error" is five.

**[ISO 24495-1:2023](https://www.iso.org/standard/78907.html)** — plain language. Writing is plain
when readers can find what they need, understand it, and act on it.

Two more worth knowing. **[GOV.UK](https://guidance.publishing.service.gov.uk/writing-to-gov-uk-standards/writing-guidelines/clear-language/)**
writes for a reading age of 9 and keeps a public list of words to avoid.
**[VOA Special English](https://simple.wikipedia.org/wiki/Wikipedia:VOA_Special_English_Word_Book)**
runs world news on about 1500 words, and that list is public.

## The test

There is no word list in this plugin. Hard words never stop arriving, so any list of them is out of
date the day it ships. Run the test instead, word by word:

1. Would a ten-year-old use this word?
2. If not, is there a plainer word that means the same thing?
3. If yes, use the plainer one. If no, keep it and move on.

Step 3 matters. `worktree`, `idempotent` and `oracle` stay. No plain word means the same thing, and
being vague costs more than being long.

## What the test throws out

Examples, not a list. The pattern is the point.

| Not this | This |
|---|---|
| `utilise`, `leverage` | use |
| `facilitate`, `assist` | help |
| `commence`, `initiate` | start |
| `ascertain` | find out |
| `sufficient` | enough |
| `in order to` | to |
| `prior to` | before |
| `additionally`, `furthermore` | also |
| `therefore`, `thus`, `hence` | so |
| `whilst` | while |
| `comprehensive` | full |
| `robust` | strong |
| `it is worth noting` | cut it |
| `great question` | cut it |

Short words can fail the test too. `hence`, `thus`, `whilst` and `deem` are one or two beats each
and no ten-year-old says them. Counting beats will never catch those. The test will.

## The rules

1. **Answer first.** One line. Then the why, if they need it.
2. **Short words.** Under three beats, unless step 3 above says keep it.
3. **Short sentences.** Under 20 words. One thought each.
4. **No wind-up.** Start at the point.
5. **Keep every fact.** Cut words, never facts. A short wrong answer is worse than a long one.
6. **Name things.** "It failed" tells them nothing. "The test failed on line 14" tells them where.

## How to cut

Read your draft and ask, line by line: would they still act the same if this line were gone?

If yes, the line goes.

Most of what goes is one of these:

- Saying what you are about to say
- Saying what you just said
- The path you took to the answer, when they only need the answer
- Praise for the question
- Words that hedge a claim you are sure of

## Do not game it

Three ways to make the numbers look good while the writing gets worse. All three are caught.

| The dodge | Why it fails |
|---|---|
| Break each clause onto its own line | Long words do not care where the lines break. Nor does the sentence count: a sentence ends at a full stop or a blank line, not at the edge of a line |
| Hide hard words in a table | Table cells count for long words too |
| Drop facts to hit the word count | Then the reply is short and wrong |

The counts are a proxy. The bar is the ten-year-old.
