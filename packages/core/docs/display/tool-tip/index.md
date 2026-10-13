---
title: Tooltip
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Tooltip"/>
<EuiSpacer @size="l" />

<EuiText>

A tooltip shows a short hint when its anchor is hovered or focused:
what an icon button does, or the full text of a truncated label.

```hbs
<EuiToolTip @content="Refresh the data" @position="top">
  <:anchor>
    <EuiButtonIcon @iconType="refresh" aria-label="Refresh" />
  </:anchor>
</EuiToolTip>
```

Keep tooltips short and **non-essential**: they don't show on touch
screens and can't hold interactive content (use a popover for that). The
anchor must be focusable (a button or link) so keyboard users see it too.
`EuiIconTip` is a ready-made "?" icon with a tooltip, e.g. next to a
label.


<EuiCallOut @title="EuiToolTip vs browser tooltip" @iconType="info">
  Always prefer <EuiCode>EuiToolTip</EuiCode> over the HTML <EuiCode>title</EuiCode> attribute. Native browser tooltips are unstyled, inaccessible on touch devices and have inconsistent screen reader support across browsers and platforms.
</EuiCallOut>

## Accessibility requirements

### Tooltip anchor

Tooltips **must** be anchored to focusable elements. If you're using a non-interactive tag (like `span` or `EuiText`), add `tabindex="0"` or preferably use an interactive one (like `EuiButton`) for built-in accessibility.

### Tooltip content

Put only plain text in tooltips. Tooltip content is not reachable by keyboard, so any interactive content (links, buttons, inputs) inside a tooltip is inaccessible, violating WCAG 2.1.1 Keyboard and WCAG 1.4.13 Content on Hover or Focus. Use `EuiPopover` for any content requiring interaction.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiToolTip

A short hint shown on hover or focus of its anchor. Keep the content
short and non-essential; it is not reachable on touch screens.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@anchorClassName` | `string` |  | Passes onto the the trigger. |
| `@className` | `string` |  | Passes onto the tooltip itself, not the trigger. |
| `@content` | `string` |  | The main content of your tooltip. |
| `@display` | `EuiToolTipDisplay` | `'inlineBlock'` | Display of the anchor wrapper: `'inlineBlock'`, `'block'` or `'flex'`. |
| `@offset` | `number` | `16` | Distance between the anchor and the tooltip. |
| `@disableScreenReaderOutput` | `boolean` | `false` | Keeps the tooltip visual only: the anchor's element is not linked to it with `aria-describedby`, and Escape does not stop propagating. Use when the anchor's label already says the same. |
| `@delay` | `ToolTipDelay` | `'regular'` | Delay before showing: `'regular'` (250ms) or `'long'` (for repeated items). |
| `@title` | `string` |  | An optional title for your tooltip. |
| `@id` | `string` |  | Unless you provide one, this will be randomly generated. |
| `@position` | `ToolTipPositions` | `'top'` | Suggested position: `'top'`, `'right'`, `'bottom'` or `'left'`. If there is not enough room for it this will be changed. |
| `@attachTo` | `undefined \| HTMLElement \| string \| null` |  | Shows the tooltip for another element (or selector) instead of the `<:anchor>` block's content. |
| `@repositionOnScroll` | `boolean` | `false` | Repositions the tooltip when any scrollable ancestor (or the window) scrolls. Needed for fixed-position anchors or a tooltip inside a scrollable container. |
| `@isShown` | `boolean \| undefined` |  | Shows (`true`) or hides (`false`) the tooltip from outside. |
| `@onMouseOut` | `(event: MouseEvent) => void` |  | If supplied, called when mouse movement causes the tool tip to be hidden. |
| `@onFocus` | `() => void` |  | Called when the anchor gets focus. |
| `@onBlur` | `() => void` |  | Called when the anchor loses focus. |
| `@hasTitle` | `boolean` | `true` | Render the title. |
| `@css` | `EuiCss` |  | Extra styles composed last into the tooltip's class (like upstream's `css` prop). Prefer this to `@className` for styles. |
| `@anchorCss` | `EuiCss` |  | Extra styles composed last into the anchor wrapper's class (like upstream's `anchorProps.css`). Prefer this to `@anchorClassName` for styles. |
| `@anchorStyle` | `string \| SafeString` |  | Inline style of the anchor wrapper (upstream's `anchorProps.style`), a style string or a safe string. |
| `@anchorProps` | `EuiToolTipAnchorProps` |  | Props for the anchor wrapper (upstream `anchorProps`), see {@link EuiToolTipAnchorProps}. |

| Block | Description |
| --- | --- |
| default block | Same as `<:anchor>`. |
| `<:title>` | The title, instead of `@title`. |
| `<:content>` | The content, instead of `@content`. |
| `<:anchor>` | The element the tooltip is for (hover/focus shows it); yields the tooltip's id for `aria-describedby`. |

### EuiIconTip

A focusable icon (a "?" by default) showing a tooltip, e.g. to explain a
setting next to its label.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@position` | `'top' \| 'right' \| 'bottom' \| 'left'` | `'top'` | Where the tooltip appears. |
| `@delay` | `'regular' \| 'long'` | `'regular'` | `'regular'` or `'long'` delay before showing. |
| `@title` | `string` |  | Bold title of the tooltip. |
| `@content` | `string` |  | The tooltip's text. |
| `@iconProps` | `{ className?: string; }` |  | Props for the icon: `{ className }`. |
| `@type` | `string` | `'question'` | The icon. |
| `@color` | `string` |  | Color of the icon, any `EuiIcon` color. |
| `@size` |  |  | Size of the icon. |
| `@ariaLabel` | `string` | "Info" | Accessible name of the icon. |
| `@anchorClassName` | `string` |  | Class for the element wrapping the icon. |
| `@onMouseOut` | `(event: MouseEvent) => void` |  | Called when the pointer leaves the icon. |
| `@display` |  |  | Display of the wrapper: `'inlineBlock'` or `'block'`. |
| `@anchorProps` |  |  | Props for the element wrapping the icon (upstream `anchorProps`), see EuiToolTip's `@anchorProps`. |
| `@offset` | `number` | `16` | Distance between the icon and the tooltip. |
| `@repositionOnScroll` | `boolean` | `false` | Repositions the tooltip when the page or a scrollable ancestor scrolls. |
| `@disableScreenReaderOutput` | `boolean` | `false` | Keeps the tooltip visual only (no `aria-describedby` on the icon), e.g. when `@ariaLabel` already says the same. |

| Block | Description |
| --- | --- |
| `<:content>` | The tooltip's content, instead of `@content`. |
| `<:title>` | The tooltip's title, instead of `@title`. |

</EuiText>
<!-- api:end -->
