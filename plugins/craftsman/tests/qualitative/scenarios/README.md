# Qualitative Test Scenarios

> YAML-based scenarios that test whether the plugin improves developer outcomes.

## Schema

```yaml
name: scenario-slug
description: What this scenario tests
skill_tested: decide-extraction  # Primary skill being exercised

trigger: |
  The exact prompt given to Claude.
  Can be multi-line.

context:
  files:
    - domain/Orders/QueryBuilders/OrderQuery.php
    - app/Http/Controllers/OrderController.php

expected:
  abstraction: "Propose Support\Concerns\FiltersTimeRange trait"
  conventions: "Use existing QueryBuilder pattern from OrderQuery"
  pushback: "Should not add logic directly to controller"
  namespace: "Support (reusable across domains)"

rubric:
  - criterion: right_abstraction
    check: "Did response propose a reusable trait in Support\Concerns?"
  - criterion: project_conventions
    check: "Did response follow the QueryBuilder pattern?"
  - criterion: anti_pattern_pushback
    check: "Did response redirect away from controller logic?"
  - criterion: correct_namespace
    check: "Did response place code in Support, not Domain?"
```

## Evaluation

Each scenario is evaluated inline against 4 criteria:

| Criterion | Question |
|-----------|----------|
| `right_abstraction` | Did Claude propose the correct pattern/structure? |
| `project_conventions` | Did Claude follow existing project patterns? |
| `anti_pattern_pushback` | Did Claude reject/redirect bad practices? |
| `correct_namespace` | Did Claude place code in the right namespace? |

**Pass threshold**: 4/4 criteria must pass.

## Running Tests

```bash
# Setup test environment first
./setup.sh

# Run evaluation
./evaluate.sh
```

## Adding Scenarios

1. Create `scenarios/<name>.yml`
2. Follow the schema above
3. Ensure `skill_tested` maps to an actual skill
4. Make `expected` values specific and verifiable
