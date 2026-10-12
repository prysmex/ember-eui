---
title: Text truncation
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Text truncation"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiTextTruncate` shortens single-line text to the width it has, with the
ellipsis at the `'end'` (default), `'start'`, `'middle'` or both ends
(`'startEnd'`), which CSS `text-overflow` cannot do. It measures the text
with a canvas in the element's own font and watches its width with a
`ResizeObserver`, recalculating when the width changes.

```hbs
<EuiTextTruncate
  @text="observability/dashboards/production/checkout-latency.json"
  @truncation="middle"
/>
```

While it truncates, the full text sits invisibly on top of the shortened
one, so selecting, double-clicking and copying get the whole string (like
`text-overflow: ellipsis`); the shortened copy is `aria-hidden` and a tooltip
shows the full text on hover. `EuiTextBlockTruncate` clamps a block of text
to a number of lines with CSS line clamping instead.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTextTruncate

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@text` (required) | `string` |  | The full text to truncate. |
| `@truncation` | `EuiTextTruncationTypes` | `'end'` | Where the ellipsis goes: `'end'`, `'start'`, `'startEnd'` (both ends, around `@truncationPosition`) or `'middle'`. |
| `@truncationOffset` | `number` | `0` | Only for `'start'` and `'end'`: number of characters at the start (`'start'`) or end (`'end'`) that are always kept. Ignored when it is not less than the text length. |
| `@truncationPosition` | `number` |  | Only for `'startEnd'`: character index the visible text is anchored on (defaults to the middle), e.g. the position of a search match. At or below 0 it truncates the end, at or beyond the text length the start. |
| `@ellipsis` | `string` | `'…'` | The truncation character(s). |
| `@width` | `number` | the measured width of the component | Available width in pixels. When given, no resize observer is set up (faster for many truncated items in one container). |
| `@onResize` | `(width: number) => void` |  | Called with the new width when the resize observer first measures and on every size change. Not called when `@width` is given. |
| `@calculationDelayMs` | `number` |  | Waits this many milliseconds after rendering before truncating, for fonts or layout that settle late. The full text shows meanwhile. |
| `@toolTipProps` | `EuiTextTruncateToolTipProps` |  | Tooltip showing the full text while truncating: `position`, `delay`, `title`, `content`, `offset`, `className` and `css` of `EuiToolTip`. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | Custom rendering of the (truncated) text, e.g. with highlighting (upstream's render prop). Receives the text to show. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiTextBlockTruncate

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@lines` (required) | `number` |  | Number of lines the text is truncated to. |
| `@cloneElement` | `boolean` |  | Styles the block's own element instead of rendering a wrapper `<div>` (upstream's `cloneElement`): apply the modifier the block receives to that single element, e.g. `<p {{clamp}}>…</p>`. |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | The text. With `@cloneElement`, receives a modifier to put on the element to truncate (a no-op otherwise). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
