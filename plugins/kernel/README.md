# Kernel

A Cognitive OS for Claude Code.

The kernel is the thinking layer. It knows **how to think**, not **what to code**.

---

## Philosophy

When code requires explanation, the abstraction is wrong. When you feel resistance, stop. The code is fighting you.

Claude is agreeable—it implements whatever you ask, even when it shouldn't. This kernel instills the instinct to push back.

---

## What You Get

```
No orientation commands    Claude already knows your project
No skill invocations       Patterns activate automatically
No context anxiety         Objectives survive compaction
No drift                   Your goal echoes before every prompt
```

---

## Skills

### Ground — Philosophy

Loaded at session start. Shapes every decision.

```
elegance       Sense resistance. Stop when code fights you.
naming         Specific over generic. Names reveal intent.
discovery      Research before implementation.
context        Manage the context budget.
recitation     Anchor objectives. Solve drift.
orientation    Load context. Solve cold start.
mechanism      Code or model. What must be deterministic.
delegation     Know when to code and when to lead.
interview      Extract requirements via questions.
topic          Isolate memory per branch.
stack          Ground the right stack for the work in front of you.
```

`ground` runs all of the above at once. It is the one you invoke.

### Craft — Building

The craftsman's way to do X.

**Artifacts**
```
adr            Architecture Decision Records
blueprint      Task tracking and roadmaps
flow           ASCII flowcharts
handoff        State transfer between sessions
map            Elegant directory trees
observation    Record learnings and discoveries
pr-stack       Pull requests that depend on each other
readme         Documentation that doesn't suck
memory         CLAUDE.md a model will not ignore
rfc            Propose a design before building it
swimlane       Who acts at each step, and what crosses between them
```

**OS Extension**
```
skill          Templates for new skills
agent          Sub-agent definitions
command        Slash command triggers
hook           OS reflexes
plugin         Plugin architecture
plugin-update  Release a version. Bump plugin.json, then commit
```

**Quality**
```
sh              Shell that reads like prose. Read it before editing shipped shell
comment         What a comment carries, and the space that means none was needed
polish          Deep code polish (seven-pass protocol)
review          Ruthless critic mentality
test            Testing philosophy (what to test, not syntax)
test-merit      Whether a test you already have earns its line
evaluate        Verify the OS is functioning
evaluate-plugin Verify plugin structure
question        Interrogate an ask before acting on it
retrospect      Find what went wrong before somebody else does
```

---

## Lifecycle

```
COLD START (SessionStart)
    │
    ├── remember   Load working.md
    └── ground     Load philosophy
    │
    ▼
PROMPT (UserPromptSubmit)              ← Anchor past → Reflect → Act
    │
    ├── anchor     Echo objective       "Here's your goal"
    ├── recite     Prompt memory update "Did you make progress?"
    ├── evaluate   Force skill YES/NO   "What skills apply NOW?"
    └── delegate   Prompt task assessment (when blueprint active)
    │
    ▼
RESPONSE (PostToolUse)
    │
    └── consider   Prompt ADR check (skips tests, config, docs)
    │
    ▼
STOP (Stop)
    │
    └── verify     Check for incomplete tasks
```

---

## Problems Solved

### Context Drift

Goals fade after 50+ tool calls. Early instructions become invisible.

**Solution:** `anchor` echoes your objective before every prompt. `recite` prompts memory updates. Both fire on `UserPromptSubmit`—the Manus pattern of constant reinforcement.

### Cold Start

New sessions begin empty.

**Solution:** `remember` loads working memory. `ground` loads philosophy.

### Skill Activation

Skills activate rarely on their own. Your patterns get ignored.

**Solution:** `evaluate` forces a YES/NO commitment on each one.

**Neither rate here is measured.** This used to say 20% naturally and 84% after,
and RFC-001 §8 row 14 has recorded that second number as *unmeasured* the whole
time. Nothing counts activations, so nothing can say whether the number is right,
stale, or invented. The mechanism is real; the arithmetic is not evidence.

### Memory Loss

Compaction discards objectives and lessons learned.

**Solution:** `working.md` persists outside context. `recite` prompts updates. Memory survives compaction if you write it down.

### Hallucination

Claude guesses methods and invents APIs.

**Solution:** `ground-discovery` instills the habit: check first, code second.

### Over-Agreement

Claude implements whatever you ask, even bad ideas.

**Solution:** `ground-elegance` instills resistance.

---

## Working Memory

Branch-aware by default. Each topic gets its own memory.

```
FOUNDRY_RUN set?  → $FOUNDRY_RUN/memory      an active floor run owns it
git branch?       → .claude/memory/<branch>
otherwise         → .claude/memory
```

One variable is the whole handshake with [floor](../floor/README.md). kernel never learns where a
run is kept and never calls floor, so each still works with the other uninstalled. `FOUNDRY_RUN`
unset — which is every session without floor — changes nothing below.

```
.claude/memory/
├── main/
│   ├── working.md
│   ├── spec.md
│   └── adr/
├── feat/auth/
│   ├── working.md
│   └── spec.md
└── fix/bug-123/
    └── working.md
```

---

## Commands

```
/design      Interview → spec → new session
/rfc         Interview → design proposal
/blueprint   Load roadmap
/polish      Deep code polish
/refine      Activate the ruthless critic
/evaluate    Verify the OS
/map         Elegant directory tree
/flow        ASCII flowchart
/handoff     Create state transfer document
/observe     Record a learning or discovery
```

---

## Output Style

Set in `.claude/settings.json`:

```json
{
  "outputStyle": "kernel:craftsman"
}
```

The Craftsman voice: direct, opinionated, elegant. No hedging.

---

## Installation

```
/plugin install kernel@the-foundry
```

The kernel is stack-agnostic. For Laravel patterns, add:

```
/plugin install laravel-ddd@the-foundry
```

For Pest testing syntax, add:

```
/plugin install pest@the-foundry
```

---

## Stack Plugin Pattern

The kernel is stack-agnostic. Stack plugins extend it with domain-specific philosophy.

### Stack Grounding

Stack plugins provide `ground-*` skills that establish framework philosophy.

The kernel's `evaluate.sh` evaluates ALL skills from ALL plugins on every prompt. When Claude detects a task requires Laravel context, it activates `ground-laravel`. Vue context? `ground-vue`.

No new hooks needed. No detection scripts. The machinery exists.

### Anatomy of a Stack Plugin

```
plugins/my-stack/
├── .claude-plugin/plugin.json
├── skills/
│   ├── ground-my-stack/      # Philosophy (recommended)
│   │   └── SKILL.md
│   ├── craft-*/              # How to build
│   └── decide-*/             # When to use what
└── README.md
```

### Skill Types

| Prefix | Purpose | When Activated |
|--------|---------|----------------|
| `ground-*` | Philosophy, mindset | Task enters stack context |
| `craft-*` | How to build | Implementation needed |
| `decide-*` | When to use what | Architectural choice |

### Writing a ground-* Skill

The description signals when to activate:

```yaml
---
name: ground-my-stack
description: My-Stack philosophy. [Core tenet]. Invoke ONCE when entering My-Stack context.
---
```

The "ONCE" hint tells Claude not to re-invoke on every prompt.

The body establishes mindset — not instructions. Philosophy, not patterns.

---

## Troubleshooting

Every hook here is silent when it works. No memory to load, no blueprint to check, no pattern
choice worth an ADR — each of those is a quiet turn, and so is a hook that could not start. You
cannot tell them apart by watching.

So kernel tells you. A preflight runs the shipped code against known input at the top of every
session and prints one line when it cannot answer:

```
kernel: hooks not running — no awk on PATH. kernel needs sh and awk, nothing else.
```

Silence from the preflight means the hooks ran. If you see that line, reinstall the plugin.

Skills not activating? Run `/evaluate`.

For anything else, `claude --debug` shows each event, the matchers it checked, and every hook's
exit code — a hook that exits 0 sends its stderr to that log and nowhere else.

### Running the hooks yourself

```bash
bash plugins/kernel/tests/run.sh
```

The suite reads `hooks.json` and fires each command the way Claude Code fires it, then breaks the
plugin one rule at a time and requires itself to go red. A suite that calls the scripts directly
proves only that the scripts work — never that the wiring does, which is where these hooks failed.

**Requires `sh` and `awk`.** Nothing else. `git` is used where it is present and done without where
it is not. There is no `bash` and no `jq`: kernel is wired through `sh`, so every script here is
POSIX, and the one place that needed to read JSON now reads it with `awk`.

---

## References

- [Sankalp: Claude Code 2.0](https://sankalp.bearblog.dev/my-experience-with-claude-code-20-and-how-to-get-better-at-using-coding-agents/)
- [Manus: Context Engineering](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus)
- [Scott Spence: Skill Activation](https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably)

---

*The best framework is the one you don't notice.*
