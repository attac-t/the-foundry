# Branding: Examples

Patterns from the framework and production code.

---

## The Pattern

### Art Directory Structure
**Why?** Every asset a package needs for professional presentation.

```text
art/
  logomark.svg
  logomark.png
  socialcard.png
  palette/
  README.md          # usage guidelines: colors, spacing, do/don't
```

### Dark/Light Responsive Banner
**Why?** Dark mode users should never see a light banner.

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="art/banner-dark.webp">
  <img alt="Package Name" src="art/banner-light.webp">
</picture>
```

Both variants live in `art/`. WebP for compression, PNG as fallback if needed.

---

## Common Scenarios

### Social Card
**Why?** Control the impression when your repo is shared on Twitter, LinkedIn, Slack.

Upload `art/socialcard.png` via Settings > General > Social preview. Recommended: 1280x640px, package name + tagline + logo. Without it, GitHub generates a generic preview.

### Consistent Cross-Package Identity
**Why?** Developers who use one package recognize another instantly.

```text
vendor/laravel-permission    -> Same banner layout, same palette
vendor/laravel-medialibrary  -> Same banner layout, same palette
vendor/laravel-activitylog   -> Same banner layout, same palette
```

The `palette/` directory documents the shared design system -- hex values, font choices, spacing rules.

### .gitattributes for Asset Exclusion
**Why?** Brand assets should not ship in production installs.

```gitattributes
/art export-ignore
/.github export-ignore
/docs export-ignore
/tests export-ignore
```

`export-ignore` ensures `composer install --prefer-dist` skips development assets.
