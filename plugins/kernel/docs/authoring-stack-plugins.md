# Authoring a Stack Plugin

The kernel is stack-agnostic on purpose. A stack plugin teaches it one
technology's philosophy — Laravel, Vue, Rust, whatever you work in.

You need no new hooks. The machinery already exists.

---

## Why It Needs No Wiring

The kernel's `evaluate` hook fires on every prompt and evaluates **every skill
from every installed plugin**. When Claude sees a Laravel task, it activates
`ground-laravel`. A Vue task activates `ground-vue`.

Ship the skills. Grounding takes care of itself.

---

## Anatomy

```
plugins/my-stack/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── ground-my-stack/       Philosophy. Start here.
│   │   └── SKILL.md
│   ├── craft-thing/
│   │   ├── SKILL.md
│   │   └── examples.md
│   └── decide-this-vs-that/
│       └── SKILL.md
└── README.md
```

Components live at the plugin root. Only `plugin.json` belongs in
`.claude-plugin/`.

---

## The Three Prefixes

| Prefix | Answers | Activates when |
|---|---|---|
| `ground-` | How should I think here? | A task enters this stack's context |
| `craft-` | How do I build X? | Implementation is needed |
| `decide-` | X or Y? | An architectural choice appears |

The prefix is not decoration. It tells Claude *when* to reach for the skill.

---

## Declare the Dependency

A stack plugin is useless without the kernel. Say so in the manifest, not in prose:

```json
{
  "name": "my-stack",
  "version": "1.0.0",
  "dependencies": ["kernel"],
  "skills": "./skills/"
}
```

Installing your plugin now installs `kernel` automatically, enabling yours enables
it, and disabling `kernel` while yours is active is blocked.

---

## The Grounding Skill

One per stack. It establishes mindset, not procedure.

```yaml
---
name: ground-my-stack
description: My-Stack philosophy. [Core tenet]. Invoke ONCE when entering My-Stack context.
---
```

Two details in that description do real work:

- **The stack name** is what Claude matches against the task.
- **"ONCE"** stops it re-invoking on every prompt.

The body is philosophy — the convictions an expert holds before they write a line.
Patterns belong in `craft-*`.

```markdown
# Skill: Ground My-Stack

> "One sentence an expert would defend."

## The Standard

- **Convention over configuration** — Follow defaults. Customize only with cause.
- **Trust the framework** — Don't abstract around it.

## The Check

Stop and rethink if:
- You are fighting a framework default
- You are writing glue to make two layers talk
```

---

## Bar for a Skill

- **Atomic.** One concept. Two concepts are two skills.
- **Brief.** Three quarters of existing skills are under 50 lines. Long code goes
  in `examples.md`.
- **Opinionated.** A skill that won't take a position isn't a skill.
- **Not the docs.** If the framework's own documentation answers it, skip it.

Run `/craft-skill` for the templates.

---

## Ship It

1. Add an entry to `.claude-plugin/marketplace.json` — `name` and `source`, no `version`.
2. Set `version` in `plugin.json`. That is the only place it lives.
3. Validate:

   ```bash
   ./.github/validate.sh
   ```

4. Write a README. `/craft-readme` has the template.

See [CONTRIBUTING.md](../../../CONTRIBUTING.md) for the full workflow.
