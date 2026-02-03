# Examples: Wrapper vs Raw

---

## Wrapper: Form Input

```vue
<!-- Use wrapper for form inputs -->
<InputTextGroup
  v-model="form.email"
  label="Email"
  name="email"
  :state="validation.email.valid"
  :message="validation.email.message"
/>

<!-- NOT raw input -->
<InputText v-model="form.email" />
<small v-if="errors.email">{{ errors.email }}</small>
```

---

## Raw: Button

```vue
<!-- Raw is fine - no validation, no label -->
<Button label="Save" severity="primary" @click="save" />
<Button label="Cancel" severity="secondary" @click="cancel" />
```

---

## Wrapper: DataTable

```vue
<!-- Use wrapper for consistent behavior -->
<AppDataTable
  v-model:selection="selected"
  v-model:first="pagination.first"
  :value="invoices"
  :columns="columns"
/>

<!-- NOT raw DataTable with manual setup -->
<DataTable :value="invoices" v-model:selection="selected">
  <Column field="number" header="Number" />
  <!-- ...repeat for each column -->
</DataTable>
```

---

## Raw: Display Components

```vue
<!-- Display only - no wrapper needed -->
<Tag :value="invoice.status" :severity="getStatusSeverity(invoice.status)" />

<ProgressBar :value="uploadProgress" />

<Badge :value="notificationCount" severity="danger" />
```

---

## Wrapper: Overlay

```vue
<!-- Use wrapper for consistent structure -->
<AppSlideOver v-model:visible="showEdit" title="Edit Invoice">
  <InvoiceForm v-model="form" />
</AppSlideOver>

<!-- NOT raw Drawer with manual responsive handling -->
```

---

## Raw: Navigation

```vue
<!-- Navigation components - no form validation -->
<Menubar :model="menuItems" />

<Breadcrumb :model="breadcrumbItems" />

<TabMenu :model="tabItems" v-model:activeIndex="activeTab" />
```

---

## Decision Flow

```
Is it a form input?
├── Yes → Use Input*Group wrapper
│         └── Adds validation, label, message
└── No → Does it need consistent multi-state binding?
         ├── Yes → Check for existing wrapper
         │         └── AppDataTable, AppSlideOver, etc.
         └── No → Is it display-only?
                  ├── Yes → Raw PrimeVue
                  └── No → Evaluate case-by-case
```

---

## Mixed Form (Anti-Pattern)

```vue
<!-- Bad: inconsistent within form -->
<form>
  <InputTextGroup v-model="form.name" label="Name" name="name" />

  <!-- Raw input breaks consistency -->
  <InputText v-model="form.email" placeholder="Email" />

  <InputSelectGroup v-model="form.status" :options="statuses" />
</form>
```

---

## Consistent Form (Good)

```vue
<!-- Good: all inputs use wrappers -->
<form>
  <InputTextGroup
    v-model="form.name"
    label="Name"
    name="name"
    :state="v.name.valid"
    :message="v.name.message"
  />

  <InputTextGroup
    v-model="form.email"
    label="Email"
    name="email"
    :state="v.email.valid"
    :message="v.email.message"
  />

  <InputSelectGroup
    v-model="form.status"
    label="Status"
    name="status"
    :options="statuses"
    :state="v.status.valid"
    :message="v.status.message"
  />
</form>
```
