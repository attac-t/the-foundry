---
name: evaluate-plugin
description: How to verify the Cognitive OS is functioning correctly.
---

# Skill: Evaluate Plugin

> "Trust, but verify."

## 1. The Principles
*   **Behavioral Testing**: Do not just check for syntax. Check for *mindset*.
*   **Isolation**: Test the Brain (Memory), Muscles (Agents), and Reflexes (Hooks) separately.

## 2. The Test Suite
### A. The Reflex Test (Hooks)
*   **Action**: Create a file that violates a convention (e.g., a file in the wrong location, or with forbidden content).
*   **Expectation**: The OS should immediately flag the violation (if configured in `hooks.json`).

### B. The Brain Test (Memory)
*   **Action**: Run `/blueprint`.
*   **Expectation**: It should load the blueprint.

### C. The Muscle Test (Agents)
*   **Action**: Run `/design "A simple cache capability"`.
*   **Expectation**: The Architect should *Plan* before *Doing*. It should use the `design` style.

## 3. Execution
Use the `/evaluate` command to run this suite interactively.
