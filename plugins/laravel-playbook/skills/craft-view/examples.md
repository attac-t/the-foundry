# View: Examples

Patterns from the framework and production code.

---

## The Pattern

### View Registration with Namespace (Standard)
**Why?** Namespace prevents silent collisions between packages.

```php
$this->loadViewsFrom(__DIR__.'/../resources/views', 'courier');

$this->publishes([
    __DIR__.'/../resources/views' => resource_path('views/vendor/courier'),
], 'courier-views');

// Consumer: view('courier::dashboard'), @include('courier::partials.tracking-status')
```

### Blade Component Registration (Spatie Package Tools)
**Why?** Declarative. One call registers class-based components with a consistent prefix.

```php
$package->name('laravel-courier')->hasViews()
    ->hasViewComponents('courier', Alert::class, StatusBadge::class);

// Consumer: <x-courier-alert type="warning" :message="$error" />
```

### Component Namespace Auto-Discovery (Filament)
**Why?** Many components? Register a namespace. PascalCase class maps to kebab-case tag.

```php
Blade::componentNamespace('Vendor\\Courier\\View\\Components', 'courier');

// Consumer: <x-courier::tracking-map :shipment="$shipment" />
```

### Anonymous Components in Packages
**Why?** Markup-only components need no class. Auto-discovered via the view namespace.

```blade
@props(['type' => 'info', 'dismissible' => false])

<div {{ $attributes->merge(['class' => "alert alert-{$type}"]) }}
     @if($dismissible) x-data="{ show: true }" x-show="show" @endif>
    {{ $slot }}
    @if($dismissible) <button @click="show = false">&times;</button> @endif
</div>
```

---

## Common Scenarios

### Published Views as a Contract
**Why?** Published views are promises. Removals and restructures are breaking changes.

```php
// Selective publishing — let consumers pick individual views
$this->publishes([/* views */], 'courier-views');
$this->publishes([/* emails only */], 'courier-email-views');
```

Laravel's override: `resources/views/vendor/courier/` always wins over the package default.

### CSS Framework Agnosticism
**Why?** Ship views that work with any CSS framework.

```blade
{{-- Bad: hardcoded Tailwind --}}
<div class="bg-red-500 text-white p-4 rounded-lg">{{ $slot }}</div>

{{-- Good: semantic classes --}}
<div {{ $attributes->merge(['class' => 'courier-alert courier-alert--error']) }}>{{ $slot }}</div>

{{-- Better: configurable theme --}}
<div {{ $attributes->class([config("courier.theme.alert.{$type}", "courier-alert--{$type}")]) }}>{{ $slot }}</div>
```

### Livewire Component Registration
**Why?** Conditional on Livewire being installed. Namespaced naming.

```php
if (class_exists(Livewire::class)) {
    Livewire::component('courier::tracking-widget', TrackingWidget::class);
    Livewire::component('courier::shipment-table', ShipmentTable::class);
}

// Consumer: <livewire:courier::tracking-widget :shipment-id="$shipment->id" />
```

### View Composers for Shared Data
**Why?** Compose data once for multiple views.

```php
View::composer('courier::*', fn ($view) => $view->with('courierVersion', Courier::VERSION));
View::composer('courier::dashboard', DashboardComposer::class);
```

### Render Hooks (Filament Pattern)
**Why?** Named injection points. Consumers add content without modifying package views.

```php
// Package Blade template
{{ FilamentView::renderHook('courier::dashboard.before') }}
<div class="courier-dashboard">{{-- content --}}</div>
{{ FilamentView::renderHook('courier::dashboard.after') }}

// Consumer registers content
FilamentView::registerRenderHook('courier::dashboard.before', fn () => view('custom-banner')->render());
```
