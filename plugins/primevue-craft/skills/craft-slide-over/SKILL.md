# Skill: Craft SlideOver

> "Right on desktop. Bottom on mobile. Always responsive."

## The Pattern

`AppSlideOver` wraps PrimeVue Drawer with responsive positioning.

```typescript
const position = computed(() =>
  isXlAndUp.value ? 'right' : 'bottom'
)

const size = computed(() => {
  if (!isXlAndUp.value) return '90%'  // Mobile height
  return props.size === 'lg' ? 'w-1/2' : 'w-1/3'  // Desktop width
})
```

## The Sizes

| Size | Desktop (xl+) | Mobile |
|------|---------------|--------|
| `md` | w-1/3         | 90% height |
| `lg` | w-1/2         | 90% height |

## The Structure

```vue
<AppSlideOver v-model:visible="showSlideOver" title="Edit Invoice" size="lg">
  <template #header-actions>
    <Button icon="pi pi-save" @click="save" />
  </template>

  <!-- Scrollable content -->
  <div>Form content here</div>

  <template #footer>
    <Button label="Cancel" @click="showSlideOver = false" />
  </template>
</AppSlideOver>
```

## The Rules

1. **Responsive positioning**: Use useTailwindBreakpoints() for detection
2. **Block scroll**: Enabled by default to prevent page scroll
3. **Sticky footer**: Footer sticks to bottom with border separator
4. **Header actions slot**: For buttons in top-right of header
5. **Title + subtitle**: Built-in header rendering with fallback slot

## The Anti-Patterns

| Don't                               | Do                                    |
|-------------------------------------|---------------------------------------|
| Hardcode drawer position            | Use responsive positioning            |
| Manual scroll blocking              | Let AppSlideOver handle it            |
| Inline close button in footer       | Close button in header (default)      |
| Forget mobile height                | 90% height on mobile always           |
