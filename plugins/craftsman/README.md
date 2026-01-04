# Craftsman

A Cognitive OS for Claude Code.

Goals stay anchored. Conventions stay enforced. Context stays managed. You never invoke it manually—it just works.

---

## Philosophy

When code requires explanation, the abstraction is wrong. When you feel resistance, stop. The code is fighting you.

Claude is agreeable—it implements whatever you ask, even when it shouldn't. This OS instills the instinct to push back. To question: *Is this necessary, or is it a symptom of a missing abstraction?*

---

## What You Get

```
No orientation commands    Claude already knows your project
No skill invocations       Patterns activate automatically
No context anxiety         Objectives survive compaction
No drift                   Your goal echoes before every prompt
```

---

## Architecture

Skills are organized into three categories.

### Ground — How to Think

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
topic          Isolate memory per branch. One topic, one branch.
```

### Decide — When to Use What

Decision frameworks for architectural choices.

```
events         Events vs direct calls
queuing        Sync vs async
pipelines      Pipelines vs sequential logic
builder        When to extract a query builder
registry       When to use a registry
composition    Compose vs inherit
extraction     When to extract a class
casts          When to use Eloquent casts
namespacing    How to organize namespaces
chunking       When to chunk operations
eager-loading  When to eager load
```

### Craft — How to Build

Implementation patterns for Laravel artifacts.

```
action         Single-responsibility actions
controller     CRUDDY controllers, thin and delegating
dto            Data transfer objects (spatie/laravel-data)
model          Eloquent models, clean and well-scoped
model-state    State machines (spatie/laravel-model-states)
query          Custom query builders
test           Pest tests
collection     Custom collections
support        Cross-cutting concerns
adr            Architecture Decision Records
map            Elegant directory trees
flow           ASCII flowcharts
```

---

## Agents

### Architect

Designs before implementing. Questions the premise.

```
Output    Blueprints, ADRs, naming decisions
Mantra    "Never write code until the names sing."
```

### Reviewer

Enforces standards without compromise.

```
Output    Critique with corrected implementation
Mantra    "The standard is the standard."
```

---

## Meta

The OS extends itself.

```
craft-skill        Templates for new skills
craft-agent        Sub-agent definitions
craft-command      Slash command triggers
craft-hook         OS reflexes
evaluate-plugin    Behavioral testing
troubleshoot-*     Debug hooks and skills
```

Templates live in `skills/meta/`.

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
CONTEXT PRESSURE (PreCompact)
    │
    └── preserve   Extract objective, constraints, failures from memory
    │
    ▼
NEXT SESSION
    │
    └── Memory persists IF updated during session
```

**Flow:** Every prompt reinforces the objective (Manus pattern). Memory updates are prompted conditionally—Claude evaluates whether progress occurred.

**Working Memory:** Template at `templates/working.md`. Rewrite sections, don't append. Blank on new goal. See `ground-recitation` skill for guidelines.

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

**Solution:** `PreCompact` preserves critical context.

### Hallucination

Claude guesses methods and invents APIs.

**Solution:** `ground-discovery` instills the habit: check first, code second.

### Over-Agreement

Claude implements whatever you ask, even bad ideas.

**Solution:** `ground-elegance` instills resistance. Agents push back.

### Token Bloat

Context fills with irrelevant history.

**Solution:** Skills load on-demand. Sub-agents work with fresh context.

---

## Commands

```
/design      Interview → spec → new session
/blueprint   Load roadmap
/refine      Spawn reviewer
/evaluate    Verify the OS
/map         Elegant directory tree
/flow        ASCII flowchart
```

---

## Output Style

Set in `.claude/settings.json`:

```json
{
  "outputStyle": "craftsman:craftsman"
}
```

This applies the Craftsman voice: direct, opinionated, elegant. No hedging.

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
│   ├── spec.md
│   └── adr/
└── fix/bug-123/
    └── working.md
```

---

## Troubleshooting

Skills not activating? Hooks silent?

```
/evaluate
```

Check:
- Scripts executable? `chmod +x hooks/*.sh`
- `jq` installed?
- Hooks in `.claude/settings.json`?

Use: `troubleshoot-hook`, `troubleshoot-skill`.

---

## References

- [Sankalp: Claude Code 2.0](https://sankalp.bearblog.dev/my-experience-with-claude-code-20-and-how-to-get-better-at-using-coding-agents/)
- [Manus: Context Engineering](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus)
- [Scott Spence: Skill Activation](https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably)

---

*The best framework is the one you don't notice.*
