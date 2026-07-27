# Kernel

A cognitive OS for Claude Code. It knows **how to think**, not **what to code**.

Stack-agnostic. Every other plugin in The Foundry builds on it.

---

## Install

```
/plugin install kernel@the-foundry
```

Verify with `/evaluate`.

---

## What Changes

```
No orientation commands    Claude already knows your project
No skill invocations       Patterns activate automatically
No context anxiety         Objectives survive compaction
No drift                   Your goal echoes before every prompt
```

---

## The Problems

| Problem | Why it happens | The fix |
|---|---|---|
| **Drift** | Goals fade after 50+ tool calls. Early instructions go invisible. | `anchor` reprints your objective every prompt. |
| **Cold start** | New sessions begin empty. | `remember` loads working memory; `ground` loads philosophy. |
| **Dead skills** | Skills in a directory activate ~20% of the time. | `evaluate` forces a yes/no on each one — 84% in [Spence's measurements][spence]. |
| **Amnesia** | Compaction discards the objective. | `working.md` lives outside the context window. |
| **Hallucination** | Claude invents methods and config keys. | `ground-discovery`: read the source, then write. |
| **Over-agreement** | Claude implements your worst idea, well. | `ground-elegance`: resistance means the abstraction is wrong. |

---

## Lifecycle

Eight hooks. All read-only — they read git state and memory files, then print text.

```
COLD START (SessionStart)
    ├── remember   Load working.md
    └── ground     Load philosophy
    │
    ▼
PROMPT (UserPromptSubmit)              ← Anchor → Reflect → Act
    ├── anchor     Echo the objective        "Here's your goal"
    ├── recite     Prompt a memory update    "Did you make progress?"
    ├── evaluate   Force a skill yes/no      "What applies NOW?"
    └── delegate   Prompt task assessment    (when a blueprint is active)
    │
    ▼
AFTER AN EDIT (PostToolUse)
    └── consider   Prompt an ADR check       (skips tests, config, docs)
    │
    ▼
STOP (Stop)
    └── verify     Flag incomplete tasks
```

Read them yourself — [`hooks/`](hooks/). None is longer than a screen.

---

## Skills

**Ground** — philosophy. Loaded at session start, shapes every decision.

```
elegance       Sense resistance. Stop when the code fights you.
naming         Specific over generic. Names reveal intent.
discovery      Research before implementation.
context        Manage the context budget.
recitation     Anchor objectives. Solve drift.
orientation    Load context. Solve cold start.
delegation     Know when to code and when to lead.
interview      Extract requirements before building.
topic          Isolate memory per branch.
stack          Ground the right framework philosophy.
```

**Craft** — how to build a thing well.

```
Artifacts       adr, blueprint, flow, handoff, map, memory,
                observation, readme, rfc
OS extension    skill, agent, command, hook, plugin, plugin-update
Quality         review, test, polish, evaluate-plugin
Upkeep          evolve, retrospect
```

Browse them all in [`skills/`](skills/), or type `/` in a session.

---

## Commands

```
/design      Interview → spec → new session
/rfc         Interview → design proposal
/blueprint   Load the task ledger
/polish      Seven-pass code polish
/refine      Spawn a ruthless reviewer
/evaluate    Verify the OS is live
/map         Annotated directory tree
/flow        ASCII flowchart
/handoff     Write a state-transfer document
/observe     Record a learning
/retrospect  Mine PRs and past sessions for lessons you never wrote down
/evolve      Audit the plugin against a moving ecosystem
/claude-md   Generate a CLAUDE.md by interview
```

---

## Memory

Branch-scoped. One topic, one memory, no cross-contamination.

```
.claude/memory/
├── main/
│   ├── working.md      Goal, constraints, focus, failures
│   ├── blueprint.md    Task ledger
│   └── adr/            Decisions, and why
├── feat/auth/
│   ├── working.md
│   └── spec.md
└── fix/bug-123/
    └── working.md
```

`working.md` is cognitive RAM: rewritten, not appended. The filesystem is
unlimited; the context window is not.

---

## Output Style

```
/output-style kernel:craftsman
```

Direct, opinionated, no hedging. Set it permanently in `.claude/settings.json`:

```json
{
  "outputStyle": "kernel:craftsman"
}
```

---

## Staying Current

Two skills run on a schedule, in opposite directions.

| Skill                                     | Runs in           | Asks                                        |
|-------------------------------------------|-------------------|---------------------------------------------|
| [`retrospect`](skills/retrospect/SKILL.md) | Your project      | What have my PRs and sessions been teaching me? |
| [`evolve`](skills/evolve/SKILL.md)        | A plugin repo     | What has the ecosystem changed under us?     |

`retrospect` reads pull request reviews, your transcripts, and git history, then
writes the corrections you would otherwise keep repeating.

`evolve` is the risky one: a recurring "what should we add?" loop only grows. So the
brake is structural rather than advisory — every plugin ships at a skill budget the
build enforces, and an addition has to name what it replaces
([ADR-002](../../docs/adr/ADR-002-skill-budgets.md)). `0 additions` is the expected
monthly result.

Weekly for `retrospect`, monthly for `evolve`. Not `/loop` — that is session-scoped
and expires after seven days. See each skill's `scheduling.md`.

---

## Extending

Writing a stack plugin? See [Authoring a stack plugin](docs/authoring-stack-plugins.md).

The short version: ship `ground-*` skills for philosophy, `craft-*` for building,
`decide-*` for choices. The kernel's `evaluate` hook already sees every skill from
every installed plugin. No new hooks required.

---

## Troubleshooting

```
/evaluate
```

If hooks are silent:

| Check | Fix |
|---|---|
| Scripts executable? | `chmod +x hooks/*.sh` |
| Plugin installed? | `claude plugin list` |
| Manifest valid? | `claude plugin validate ./plugins/kernel --strict` |

---

## References

- [Manus: Context Engineering](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus) — recitation, filesystem as memory
- [Scott Spence: Skill Activation][spence] — the 20% and 84% figures
- [Sankalp: Claude Code 2.0](https://sankalp.bearblog.dev/my-experience-with-claude-code-20-and-how-to-get-better-at-using-coding-agents/)

[spence]: https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably

---

## License

[MIT](../../LICENSE)

---

*The best framework is the one you don't notice.*
