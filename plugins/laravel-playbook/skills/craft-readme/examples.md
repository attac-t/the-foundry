# README: Examples

Patterns from the framework and production packages.

---

## The Pattern

### Benefit-Driven H1 + Immediate Code

**Why?** The H1 sells value. The code proves it.

```markdown
# Associate users with permissions and roles

Once installed you can do stuff like this:

\```php
$user->assignRole('writer');
$user->givePermissionTo('edit articles');
\```
```

Casual confidence. No ceremony.

### Badge Row

**Why?** Three signals: version, build status, adoption.

```markdown
[![Latest Version on Packagist](https://img.shields.io/packagist/v/vendor/package.svg?style=flat-square)](...)
[![GitHub Tests Action Status](https://img.shields.io/github/actions/workflow/status/vendor/package/run-tests.yml?style=flat-square)](...)
[![Total Downloads](https://img.shields.io/packagist/dt/vendor/package.svg?style=flat-square)](...)
```

### Dark/Light Responsive Banner

**Why?** Dark mode users are half your audience.

```html
<div align="left">
  <a href="https://yourorg.com/open-source?utm_source=github&utm_medium=banner&utm_campaign=package-name">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="art/banner-dark.webp">
      <img alt="Package Name" src="art/banner-light.webp">
    </picture>
  </a>
</div>
```

---

## Common Scenarios

### Alternatives Section

Listing competitors is a confidence move:

```markdown
## Alternatives

- [bouncer](https://github.com/JosephSilber/bouncer)
- [laratrust](https://github.com/santigarcor/laratrust)
```

### Section Order (Full Template)

```
1. Header image (dark/light responsive via <picture>)
2. H1 slogan (benefit statement)
3. Badges
4. Brief description + code example
5. Documentation link (if docs site exists)
6. Installation (abbreviated)
7. Testing
8. Changelog
9. Contributing
10. Security Vulnerabilities
11. Credits
12. Alternatives (optional, but a confidence move)
13. License
```

### Taylor's Minimal README Style

First-party packages keep the README thin and link to official docs:

```markdown
# Laravel Scout

Laravel Scout provides a driver based solution to searching your Eloquent models.

## Official Documentation

Documentation for Scout can be found on the [Laravel website](https://laravel.com/docs/scout).
```

The framework docs carry the weight. The README is just the signpost.
