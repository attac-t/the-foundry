---
name: troubleshoot-skill
description: How to debug the OS Knowledge (Skills).
---

# Skill: Troubleshoot Skill

> "When the knowledge is missing."

## Skill Discovery

Claude Code requires **flat** skill directories:

```
skills/skill-name/SKILL.md     ✅ Works
skills/category/skill-name/    ❌ Not discovered
```

One level deep only.

## Common Failures

### Skill Not Discovered

1. Check directory structure - flat, not nested
2. Check `SKILL.md` exists with valid frontmatter
3. Reinstall plugin after changes

### Skill Not Triggered

1. Natural prompt doesn't match skill intent
2. Too many skills competing - keep atomic
3. Skill not registered in agent definitions

### Agent Doesn't Know Skill

Sub-agents don't inherit skills. Register explicitly:

```markdown
# agents/architect.md
skills:
  - craft-action
  - craft-model
```

**Unregistered skills do not exist** for that agent.

## Debug Steps

1. Check `skills/` structure is flat
2. Verify frontmatter: `name:` and `description:`
3. Check skill listed in `<available_skills>`
4. For agents, verify skill in agent definition
5. Reinstall: `/plugin uninstall` then `/plugin install`
