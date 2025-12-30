---
name: craft-command
description: How to craft a Slash Command trigger.
---

# Skill: Craft Command

> "The Voice of the System."

## 1. The Principles
*   **Trigger Only**: A command should rarely contain logic. It should just *invoke* an Agent or a Skill.
*   **Naming**: Use "Verb-Noun" or "Elegant Terms" (e.g., `/blueprint`, `/design`, `/refine`).
*   **Safety**: Use `allowed-tools` frontmatter to restrict capabilities (e.g., Read-Only for planning commands).

## 2. The Implementation
*   **Official Spec**: Use `claude-code-guide` agent to query slash command documentation.
*   **Pattern**:
    ```markdown
    ---
    description: Spawns the Architect.
    argument-hint: [task description]
    ---
    /agents/architect "$ARGUMENTS"
    ```
    (Explicitly pass the user input using `$ARGUMENTS`).
