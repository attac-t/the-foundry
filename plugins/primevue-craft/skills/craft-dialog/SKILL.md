# Skill: Craft Dialog

> "Dialogs with structure. Modals with purpose."

## The Pattern

`AppDialog` wraps PrimeVue Dialog with semantic slots and sensible defaults.

```vue
<AppDialog v-model:visible="showDialog">
  <template #header>Title</template>

  Content goes here

  <template #footer>
    <Button label="Cancel" @click="showDialog = false" />
    <Button label="Save" @click="save" />
  </template>
</AppDialog>
```

## The Defaults

```typescript
{
  modal: true,
  closable: true,
  draggable: false,
  dismissableMask: false
}
```

## The Variants

### AppDialog (Simple Wrapper)
- Two-way visible binding
- Three slots: header, default, footer
- Passes through all attrs

### ConfirmationModal (Higher-Level)
- Wraps custom Modal component
- Title, content, action props
- Processing state support
- Submit/Cancel events

## The Rules

1. **Semantic slots**: Use #header, #default, #footer
2. **Visibility control**: Parent owns visible state
3. **Processing state**: Disable submit during processing
4. **Escape handling**: Modal closes on Escape key

## The Anti-Patterns

| Don't                               | Do                                   |
|-------------------------------------|--------------------------------------|
| Create inline modal structure       | Use AppDialog or ConfirmationModal   |
| Forget processing state             | Disable submit when processing       |
| Manual escape key handling          | Let wrapper handle it                |
| Mix visible logic in child          | Parent controls visibility           |
