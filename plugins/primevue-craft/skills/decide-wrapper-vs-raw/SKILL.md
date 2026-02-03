# Skill: Decide Wrapper vs Raw

> "Wrap for consistency. Raw for exceptions."

## The Heuristic

```
Used in multiple places?     → Wrapper
Needs consistent validation? → Wrapper
Standard form input?         → Wrapper (InputGroup)
One-off custom UI?           → Raw PrimeVue
Layout component only?       → Raw PrimeVue
```

## Quick Test

Ask: "Will this pattern repeat?"

- **Yes, in forms** → Use Input*Group wrapper
- **Yes, in tables** → Use TwnDataTable wrapper
- **Yes, in overlays** → Use TwnDialog/TwnSlideOver
- **No, one-off** → Raw PrimeVue is fine
- **No, layout only** → Raw PrimeVue (no validation needed)

## The Comparison

| Wrapper                        | When to Use                               |
|--------------------------------|-------------------------------------------|
| Input*Group                    | Any form input needing validation         |
| TwnDataTable                   | Tables with selection, sorting, pagination|
| TwnDialog                      | Modals with semantic structure            |
| TwnSlideOver                   | Side panels with responsive behavior      |
| TwnPanel                       | Collapsible sections with lazy content    |

| Raw PrimeVue                   | When to Use                               |
|--------------------------------|-------------------------------------------|
| Button                         | Standalone, no wrapper needed             |
| Tag                            | Simple display, no validation             |
| ProgressBar                    | Display-only, no form integration         |
| Menu/Menubar                   | Navigation, no form validation            |
| Toast                          | Global notification, managed by store     |

## When Raw is Fine

```vue
<!-- Simple button - no wrapper needed -->
<Button label="Save" @click="save" />

<!-- Display tag - no validation -->
<Tag :value="status" :severity="getSeverity(status)" />

<!-- Progress indicator -->
<ProgressBar :value="progress" />
```

## When Wrapper is Required

```vue
<!-- Form input - needs validation, label, message -->
<InputTextGroup
  v-model="name"
  label="Name"
  name="name"
  :state="validation.name.valid"
  :message="validation.name.message"
/>

<!-- Table - needs consistent column handling -->
<TwnDataTable
  v-model:selection="selected"
  :value="items"
  :columns="columns"
/>
```

## The Anti-Patterns

| Don't                                    | Do                               |
|------------------------------------------|----------------------------------|
| Wrap every PrimeVue component            | Wrap only when adding value      |
| Use raw inputs in forms                  | Use Input*Group for consistency  |
| Create wrapper without clear benefit     | Document why wrapper exists      |
| Mix raw and wrapped in same form         | Be consistent within form        |
