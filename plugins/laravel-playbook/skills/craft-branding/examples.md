# Branding: Examples

Patterns from production packages.

---

## The Pattern

### Art Directory Structure

**Why?** Every asset a package needs for professional presentation.

```
art/
  README.md
  logomark.png
  logomark.svg
  logomark@2x.png
  logomark@3x.png
  logomark@4x.png
  palette/
  socialcard.png
```

### Dark/Light Responsive Banner

**Why?** Dark mode users should never see a light banner.

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

Both variants live in `art/`. WebP for compression, PNG as fallback if needed.
