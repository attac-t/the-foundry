# Skill: Craft Input Group

> "Stack architecture. Consistent forms."

## The Pattern

Form groups use a composable stack architecture:

```
IftaOrFloatLabel (conditional wrapper)
└── InputLabelMessageGroup (label + validation)
    └── PrimeVue Component (InputText, Select, etc.)
        └── Optional trailing slot
```

## The Stack

### 1. IftaOrFloatLabel
Conditional component wrapper using `:is`:
- 'float' → FloatLabel
- 'ifta' → IftaLabel
- undefined → plain div

### 2. InputLabelMessageGroup
Separates layout from input:
- Float/IFTA: renders above input
- Traditional: renders InputLabel + optional inline layout
- Shows InputError when state === false

### 3. PrimeVue Component
The actual input with:
- v-model binding
- invalid state conversion
- Trailing slot support

## The Rules

1. **Label type abstraction**: Use IftaOrFloatLabel for conditional wrapping
2. **Validation three-state**: true (valid), false (invalid), null (neutral)
3. **Placeholder proxy**: Float labels get empty placeholder
4. **Unique field names**: Generate with uniqueId() for label association
5. **Trailing slot**: Optional content after input (icons, help)

## The Anti-Patterns

| Don't                               | Do                                    |
|-------------------------------------|---------------------------------------|
| Duplicate validation styling        | Use InputLabelMessageGroup            |
| Conditional import for label types  | Use IftaOrFloatLabel abstraction      |
| Manual placeholder handling         | Use placeholder proxy pattern         |
| Hardcode field names                | Generate with uniqueId()              |
