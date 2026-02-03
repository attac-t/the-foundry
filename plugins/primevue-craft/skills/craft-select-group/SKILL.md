# Skill: Craft Select Group

> "Selects with add buttons. Options with actions."

## The Pattern

`InputSelectGroup` wraps PrimeVue Select with footer slot for "add new" pattern.

```vue
<InputSelectGroup
  v-model="form.customer_id"
  :options="customers"
  option-label="name"
  option-value="id"
  label="Customer"
  name="customer"
  allow-add
  @add="openAddCustomerModal"
/>
```

## The Add Button Pattern

Footer slot contains optional `TwnAddBtn` for adding new options:

```vue
<template #footer>
  <TwnAddBtn v-if="allowAdd" @click="emit('add')" />
</template>
```

## The Rules

1. **Slot forwarding**: Forward all slots to Select dynamically
2. **Footer for add**: Use footer slot for "add new" action
3. **Change event**: Emit change with `event.value`
4. **Show clear**: Optional clear button for nullable selections
5. **Loading state**: Support async option loading

## The Anti-Patterns

| Don't                               | Do                                    |
|-------------------------------------|---------------------------------------|
| Inline add button logic             | Use allowAdd prop + @add emit         |
| Manual slot forwarding              | Loop over $slots                      |
| Forget loading state                | Support loading prop                  |
| Skip showClear for nullable         | Add showClear when null is valid      |
