---
name: decide-extraction
description: When and how to extract application code into a standalone Laravel package. The extraction playbook.
---

# Skill: Package Extraction

> "Every great package started as someone's application code that solved a problem worth sharing."

## The Decision

**Extract when:**
- The code solves a PHP problem, not a project problem
- You've copy-pasted it across two or more projects already
- Other developers ask "how did you build that?" -- demand is real
- The feature has a clean boundary: inputs go in, outputs come out, no tentacles into your domain
- Existing solutions have poor DX, are abandoned, or miss your use case entirely

**Don't extract when:**
- The code is glued to your domain model (leaky abstractions hurt everyone)
- You'd need to expose internal business logic to make it work
- A well-maintained package already does this with good DX -- contribute upstream instead
- The feature only makes sense inside your specific application context
- You're extracting for the resume, not for the ecosystem

## The Heuristic

Ask: *"Does this code solve a PHP problem or a project problem?"*

PHP problems are extractable. Project problems are not.

## The Quick Test

| Ask                                                | Answer | Action                        |
| -------------------------------------------------- | ------ | ----------------------------- |
| Have you copy-pasted this across projects?         | Yes    | Strong extraction signal      |
| Does it depend on your domain models?              | Yes    | Decouple first, then reassess |
| Do existing packages solve this well?              | Yes    | Contribute upstream instead   |
| Can you replace all `App\` refs with generics?     | Yes    | Clean boundary -- extract     |
| Would other Laravel developers use this?           | No     | Keep it internal              |
| Is the existing solution abandoned or has poor DX? | Yes    | Extract with better DX        |
| Can you explain what it does in one sentence?      | Yes    | Right scope for a package     |

## Real-World Examples

See [examples.md](examples.md).
