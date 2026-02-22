---
name: craft-branding
description: Crafting package identity. Professional impressions from the first click.
---

# Skill: Craft Branding

> "A package without branding is a book without a cover. It works, but nobody picks it up."

## The Standard

1. **`art/` directory**: Contains all brand assets. Present in every mature package. SVG source files, PNG exports at multiple resolutions, social cards, and palette documentation. The `art/` directory is not vanity -- it is professionalism. It signals that maintainers care about the details beyond code.

1. **Logomark at multiple resolutions**: SVG as the source of truth. PNG exports at 1x, 2x, 3x, and 4x for every context -- README, docs, social, print. A single-resolution PNG looks blurry on retina displays, and retina is the default.

1. **Social card**: A `socialcard.png` for link previews on Twitter, LinkedIn, and Slack. When someone shares your GitHub URL, the social card is the first thing they see. No social card means an ugly auto-generated preview. Professional packages control this impression.

1. **Dark/light responsive banners**: Use the `<picture>` element with `prefers-color-scheme` media query. Dark mode users should never see a light banner. Both variants live in `art/`. WebP for compression, PNG as fallback if needed.

1. **UTM tracking on banner links**: Link banner images to your org page with UTM parameters. This tells you which packages drive traffic. The parameters: `utm_source=github`, `utm_medium=banner`, `utm_campaign={package-name}`.

1. **Consistent identity across packages**: If you maintain multiple packages, share a visual language -- color palette, typography, layout. A developer who uses one of your packages should recognize another instantly. The `palette/` directory documents the shared design system.

## The Anti-Patterns

| Don't                                | Do                                          | Why                                                               |
|--------------------------------------|---------------------------------------------|-------------------------------------------------------------------|
| No branding at all                   | `art/` directory with full asset set        | First impressions are visual -- no branding signals hobby project |
| Single resolution PNG                | SVG source + 1x through 4x PNG exports      | Retina is the default -- blurry logos erode trust                 |
| No social card                       | `socialcard.png` in `art/`                  | You control the impression or the platform generates one for you  |
| Light-only banner                    | Dark/light variants via `<picture>` element | Dark mode users are half your audience                            |
| Untracked banner links               | UTM parameters on all banner hrefs          | Know which packages drive traffic to your org                     |
| Inconsistent visuals across packages | Shared palette and layout language          | Brand recognition compounds across your portfolio                 |

## Real-World Examples

See [examples.md](examples.md).
