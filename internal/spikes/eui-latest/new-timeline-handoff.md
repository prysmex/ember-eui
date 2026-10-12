# New components: EuiTimeline family

Branch `feat/eui-latest`. Target EUI 123.1.0 / Borealis 8.1.0. Status:
**In progress** until the Chromium suite can run in the current environment.

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
- Existing extracted factory parity: pending final rerun after docs only.
- Browser execution: blocked because the prior Linux Chromium cache is gone;
  downloading Playwright Chromium requires sandbox approval for
  `cdn.playwright.dev`.

## Next step

After browser access is restored, run the six focused tests, then the full core
suite. If clean, change the four inventory rows to Migrated, record the final
counts here, and run the site acceptance/build checks.
