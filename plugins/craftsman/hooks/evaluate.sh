#!/bin/bash
# UserPromptSubmit: Forces skill evaluation before work begins
#
# Based on Scott Spence's forced evaluation pattern
# https://scottspence.com/posts/how-to-make-claude-code-skills-activate-reliably
#
# Purpose: Ensure relevant skills are activated, not ignored.

cat <<'EOF'
---
**Skill Evaluation** (required before implementation)

**Step 1 - EVALUATE:**
For each skill in <available_skills>: `[skill]` - YES/NO - [reason]

**Step 2 - ACTIVATE:**
For each YES → call `Skill(skill-name)` NOW.

**Step 3 - IMPLEMENT:**
Only after activation, proceed with the task.
EOF
