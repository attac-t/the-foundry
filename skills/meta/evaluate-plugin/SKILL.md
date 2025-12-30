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
*   **Action**: Create a file named `BadController.php`.
*   **Expectation**: The OS should immediately scream about "Traffic Cop" rules (if configured in `hooks.json`).

### B. The Brain Test (Memory)
*   **Action**: Run `/craft:blueprint`.
*   **Expectation**: It should load `implementation_plan.md`.

### C. The Muscle Test (Agents)
*   **Action**: Run `/craft:design "A simple cache service"`.
*   **Expectation**: The Architect should *Plan* before *Doing*. It should use the `design` style.

## 3. Execution
Use the `/craft:evaluate` command to run this suite interactively.
