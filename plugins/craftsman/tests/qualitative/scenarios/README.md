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
    - domain/Orders/Data/OrderData.php

expected:
  discovery: "Should read OrderQuery.php and OrderData.php first"
  abstraction: "Propose Support\Concerns\FiltersTimeRange trait"
  conventions: "Use existing QueryBuilder pattern from OrderQuery"
  pushback: "Should not add logic directly to controller"
  namespace: "Support (reusable across domains)"
  correctness: "Generated code should be syntactically valid PHP"

rubric:
  - criterion: discovery_first
    check: "Did Claude read existing files before proposing changes?"
  - criterion: right_abstraction
    check: "Did response propose a reusable trait in Support\Concerns?"
  - criterion: project_conventions
    check: "Did response follow the QueryBuilder pattern?"
  - criterion: anti_pattern_pushback
    check: "Did response redirect away from controller logic?"
  - criterion: correct_namespace
    check: "Did response place code in Support, not Domain?"
  - criterion: code_correctness
    check: "Is the generated code syntactically valid?"
```

## Evaluation

Each scenario is evaluated inline against 6 criteria:

| Criterion | Question |
|-----------|----------|
| `discovery_first` | Did Claude read existing code before writing new code? |
| `right_abstraction` | Did Claude propose the correct pattern/structure? |
| `project_conventions` | Did Claude follow existing project patterns? |
| `anti_pattern_pushback` | Did Claude reject/redirect bad practices? |
| `correct_namespace` | Did Claude place code in the right namespace? |
| `code_correctness` | Is the generated code syntactically valid? |

**Pass threshold**: 6/6 criteria must pass.

## Why 6 Criteria?

| Original 4 | Added 2 | Why Added |
|------------|---------|-----------|
| abstraction, conventions, pushback, namespace | discovery_first | Plugin emphasizes reading before writing |
| | code_correctness | Elegant code that doesn't work is worthless |

## Baseline Comparison

> "Would Claude do this without the plugin?" — The question we must answer.

Each scenario includes a `baseline` field documenting what vanilla Claude would likely do:

```yaml
baseline:
  likely_response: "Add between() method directly to OrderQuery"
  missing_inference: "Would not propose Support trait without plugin context"
  plugin_difference: "Plugin teaches extraction to Support for reusability"
```

### A/B Testing Protocol

Full baseline comparison requires two sessions:

1. **Session A (Plugin)**: Run scenario with plugin loaded, record response
2. **Session B (Vanilla)**: Same trigger in fresh Claude session without plugin
3. **Compare**: Did plugin session demonstrate superior architectural inference?

### Baseline Expectations by Scenario

| Scenario | Vanilla Claude Likely Does | Plugin-Enhanced Should Do |
|----------|---------------------------|---------------------------|
| time-range | Adds method inline to OrderQuery | Extracts to Support\Concerns trait |
| api-design | Creates PointsController with 4 methods | CRUDDY with action controllers |
| fat-controller | Implements in controller with comments | Redirects to Domain Action class |
| vague-naming | Creates DateHelper class | Pushes back, proposes specific name |
| query-complexity | Adds filterByAll() method | Proposes composable chainable methods |

## Self-Evaluation Limitations

> Research shows self-evaluation has biases. Mitigations:

1. **Specific checks**: Each criterion has a concrete yes/no question
2. **Evidence required**: Responses must cite which files were read
3. **Syntax validation**: Code correctness can be objectively verified
4. **Baseline awareness**: Document what vanilla Claude would do
5. **Future**: Consider cross-model evaluation (Haiku evaluates Opus)

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
5. Include all 6 rubric criteria
