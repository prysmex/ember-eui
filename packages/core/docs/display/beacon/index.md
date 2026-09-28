---
title: Beacon
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Beacon"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiBeacon` is a pulsing dot that draws the eye to something new or
something a guided tour points at. Use it sparingly: one on screen at a
time.

```hbs
<EuiBeacon />
<EuiBeacon @size={{20}} />
```

It is decorative: describe what it points at in the text next to it, or
with `aria-label` on the element it marks.

</EuiText>

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

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
