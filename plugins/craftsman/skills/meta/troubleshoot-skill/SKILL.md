---
name: troubleshoot-skill
description: How to debug the OS Knowledge (Skills).
---

# Skill: Troubleshoot Skill

> "When the knowledge is missing."

## 1. The Principles
*   **Registration**: The #1 cause of failure. Skills are not magical; they must be registered.
*   **Syntax**: Frontmatter must be exact.

## 2. The Implementation
*   **Official Guide**: Use `claude-code-guide` agent to query skill troubleshooting steps.

## 3. Common Pitfalls
*   **The Silent Failure**: If the agent "doesn't know" how to do X, check `agents/architect.md`. Is the skill listed?
*   **Context Limit**: Too many skills can confuse the model. Keep them atomic.
