---
title: Beacon
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Beacon"/>
<EuiSpacer @size="l" />

<EuiText>

Use the `EuiBeacon` component to draw visual attention to a specific location or element. It is decorative: describe what it points at in the text next to it, or with `aria-label` on the element it marks.

</EuiText>
<EuiSpacer />
<EuiCallOut @color="success" @size="s" @title="Use with EuiTour">
  <p>It is strongly encouraged to use <strong>EuiBeacon</strong> in conjunction with <strong>EuiTour</strong>. Standalone, the beacon is a visual cue that may lack context.</p>
</EuiCallOut>
<EuiSpacer />

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiBeacon

A pulsing dot that draws attention to something new, e.g. next to a
feature a tour points at.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` | `number` | `12` | Diameter of the center dot in px. |
| `@color` | `EuiBeaconColor` | `'success'` | `'subdued'`, `'primary'`, `'success'`, `'accent'`, `'danger'` or `'warning'`. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
