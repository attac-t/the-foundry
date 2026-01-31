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
delegation     Know when to code and when to lead.
interview      Extract requirements via questions.
topic          Isolate memory per branch.
```

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
readme         Documentation that doesn't suck
```

**OS Extension**
```
skill          Templates for new skills
agent          Sub-agent definitions
command        Slash command triggers
hook           OS reflexes
plugin         Plugin architecture
```

**Quality**
```
review          Ruthless critic mentality
test            Testing philosophy (what to test, not syntax)
evaluate        Verify the OS is functioning
evaluate-plugin Verify plugin structure
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
    └── evaluate   Force skill YES/NO   "What skills apply NOW?"
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

Skills activate ~20% naturally. Your patterns get ignored.

**Solution:** `evaluate` forces YES/NO commitment. Activation jumps to 84%.

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

Branch-aware. Each topic gets its own memory.

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
/blueprint   Load roadmap
/refine      Spawn reviewer
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

Skills not activating? Hooks silent?

```
/evaluate
```

Check:
- Scripts executable? `chmod +x hooks/*.sh`
- Plugin installed? `/plugins list`

Run `/evaluate` to verify hooks are firing.

---

## References

- [Sankalp: Claude Code 2.0](https://sankalp.bearblog.dev/my-experience-with-claude-code-20-and-how-to-get-better-at-using-coding-agents/)
- [Manus: Context Engineering](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus)
- [Scott Spence: Skill Activation](https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably)

---

*The best framework is the one you don't notice.*
