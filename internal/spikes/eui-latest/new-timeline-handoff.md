# New components: EuiTimeline family

Branch `feat/eui-latest`. Target EUI 123.1.0 / Borealis 8.1.0. Status:
**Migrated**.

## Components and API

- `EuiTimeline`: `<ol role="list">`, `@gutterSize` m/l/xl (default xl),
  `@items` for simple string events, a default block for rich items, and
  `@css`.
- `EuiTimelineItem`: `<li>` composing the icon and event, `@icon`,
  `@iconAriaLabel`, `@verticalAlign` center/top, custom `<:icon>` block, and
  `@css`.
- `EuiTimelineItemIcon`: subdued EuiAvatar for an icon type or custom block;
  logical inline-end spacing, high-contrast content outline, and `@css`.
- `EuiTimelineItemEvent`: flexible event wrapper with center/top alignment and
  `@css`.

All style getters are `@cached`; theme-dependent factories use
`useEuiBorealisStyles`, while the two theme-independent factories are hoisted.
The timeline includes the list reset normally supplied by React's global
styles. Existing extracted factories are reused without generator changes.

## Ember differences

Upstream accepts React nodes both through `items` and `children`. Ember uses
the default block for rich content. The optional `@items` convenience accepts
`{ content: string, icon, iconAriaLabel, verticalAlign }`; it renders before
the block. A custom React element icon maps to the `<:icon>` named block.

## Tests

`eui-timeline-test.gts` has six focused tests covering:

- ordered-list/a11y semantics, attributes, icon labels and nested structure;
- upstream flex/gutter/reset/connector-line computed styles;
- reactive gutter and vertical alignment without element replacement;
- custom icon content, direct subcomponents, and `@css` composition;
- simple items combined with block content;
- JS-object token overrides, preferred contrast, RTL logical spacing and
  sibling provider isolation.

## Checks (2026-10-12)

- `ember-tsc --noEmit`: pass.
- ESLint on new components, registries and focused tests: pass.
- Core Rollup build (including declarations and package exports): pass.
- Vite browser-test build: pass (3153 modules).
- API docs generation/check: pass (99 pages; one updated).
- Existing extracted factory parity: 309/309.
- Focused Chromium 141 timeline suite: 6/6.
- Full core Chromium 141 suite: 1134/1134.
- Site checks: Node 8/8, acceptance 17/17 and development build pass. The four
  added docs entries required updating the navigation count from 100 to 104;
  the catalog route test takes about 45s on ARM, so the site now uses core's
  existing 120s Testem browser-disconnect timeout.

The RTL override test now checks the connector at logical inline-start
(`border-right` in RTL), rather than incorrectly inspecting its physical left
edge. No component implementation change was needed.
