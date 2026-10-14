# DESIGN.md: Homelab Dashboard

## Source
- URL: https://jnsgr.uk/2024/03/a-homelab-dashboard-for-nixos/
- Capture date: 2026-09-25
- Evidence: Firecrawl branding data and dashboard screenshots in `.firecrawl/`

## Reference Screenshot
![Homelab dashboard reference](./.firecrawl/dashboard-reference.webp)

Use the screenshot as the source of truth for layout, hierarchy, density, and feel.

## Design Summary
An information-dense, dark slate operations dashboard. A slim resource and search row sits above clearly named groups of broad service cards. Decoration is minimal; icons, short descriptions, and consistent alignment carry the hierarchy.

## Design Tokens

### Colors
- Canvas: slate 800, approximately `#1e293b` (inferred)
- Cards: slate 700, approximately `#334155` (inferred)
- Card details: darker translucent slate
- Primary text: slate 100
- Secondary text: slate 400
- Accent: service icons retain their recognizable colors

### Typography
- Use Homepage's system sans-serif stack.
- Group headings are modest, regular-weight labels rather than display type.
- Service names are medium weight; descriptions and metrics are smaller and muted.

### Spacing And Layout
- Full-width page with compact outer padding.
- Four equal cards per desktop row, collapsing naturally on narrow screens.
- Tight vertical rhythm between group heading and cards.
- Medium card radius, no heavy borders, and little or no shadow.

## Components
- Top row: host resources followed by a wide search field.
- Service card: icon, short name, one-line description, full-card link.
- Group: lowercase or concise heading over a responsive card row.
- Footer controls remain Homepage defaults.

## Page Patterns
- Resources and search first.
- Operational and frequently used services before media and publishing links.
- Keep card descriptions functional and short.
- On mobile, preserve card readability by reducing columns rather than shrinking text.

## Content Style
- Plain, technical, low-energy labels.
- Names identify the product; descriptions identify its purpose.
- Avoid marketing language and decorative copy.

## Agent Build Instructions
- Use Homepage's built-in `dark` theme and `slate` palette.
- Use native Homepage layout and widgets; do not reproduce the interface with custom CSS.
- Configure four-column row groups and let Homepage handle responsive breakpoints.
- Do not add service API widgets unless their credentials are already managed declaratively.

## Rerun Inputs
workflow: firecrawl-website-design-clone
source_url: https://jnsgr.uk/2024/03/a-homelab-dashboard-for-nixos/
target_stack: NixOS homepage-dashboard module
output: DESIGN.md
