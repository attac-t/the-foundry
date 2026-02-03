# Skill: Craft Panel

> "Clickable headers. Lazy content."

## The Pattern

`AppPanel` wraps PrimeVue Panel with enhanced interaction and lazy rendering.

```vue
<AppPanel
  v-model:collapsed="isCollapsed"
  header="Invoice Details"
  :badge="{ value: 3, severity: 'danger' }"
>
  <!-- Content only renders when expanded -->
</AppPanel>
```

## The Enhancements

| Feature          | Implementation                                 |
|------------------|------------------------------------------------|
| Clickable header | Entire header toggles, not just chevron        |
| Custom chevron   | pi-chevron-right (collapsed) / pi-chevron-down |
| Badge support    | Optional badge in top-right corner             |
| Lazy content     | Slot only renders when expanded                |
| Disabled state   | Prevents toggling, dims header                 |

## The Rules

1. **Full header click**: Entire header area toggles panel
2. **Lazy content**: Use v-if on slot for performance
3. **Disabled styling**: opacity-50 on header when disabled
4. **Badge position**: Top-right of header
5. **Hover state**: bg-surface-100 transition on header

## The Anti-Patterns

| Don't                  | Do                                |
|------------------------|-----------------------------------|
| Only chevron clickable | Make entire header clickable      |
| Always render content  | Lazy render with v-if             |
| Skip disabled visual   | Add opacity-50 when disabled      |
| Inline badge styling   | Use severity prop for consistency |
