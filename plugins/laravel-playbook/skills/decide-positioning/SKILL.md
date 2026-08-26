---
name: decide-positioning
description: How to evaluate the competitive landscape and position your package. Build it because it's better, not because you can.
---

# Skill: Package Positioning

> "Build it because it's better, not because you can."

## The Decision

**Build when:**
- No existing solution covers your use case
- Existing solutions have poor DX, are abandoned, or are unmaintained
- You can offer meaningfully better developer experience (not marginally -- meaningfully)
- The existing package's architecture prevents the improvement you need (contributing upstream won't work)
- You've identified a genuine gap, not just a preference

**Contribute when:**
- A well-maintained package exists with good DX
- Your improvement fits within the existing architecture
- The maintainer is responsive to PRs
- Your "new package" would be 80% identical to what exists

**Wait when:**
- You haven't installed and used the alternatives
- Your differentiation is theoretical, not tested
- The problem might not be worth solving as a package (see [decide-extraction](../decide-extraction/SKILL.md))

## The Heuristic

Ask: *"Can I explain in one sentence why a developer should choose this over what already exists?"*

If no, either sharpen your differentiation or contribute to an existing package instead.

## The Quick Test

| Ask                                                | Answer | Action                               |
| -------------------------------------------------- | ------ | ------------------------------------ |
| Have you searched Packagist for alternatives?      | No     | Stop. Research first                 |
| Have you installed and used the top alternatives?  | No     | Stop. Evaluate DX first              |
| Can you name your differentiation in one sentence? | No     | Not ready to build                   |
| Is the best alternative abandoned (12+ months)?    | Yes    | Strong signal to build               |
| Would your improvement fit as a PR upstream?       | Yes    | Contribute, don't compete            |
| Does your positioning statement feel forced?       | Yes    | You don't have a real differentiator |
| Can you fill the DX comparison table honestly?     | Yes    | You've done the research             |

## Real-World Examples

See [examples.md](examples.md).
