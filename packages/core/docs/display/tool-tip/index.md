---
title: Tooltip
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Tooltip"/>

<EuiSpacer @size='l' />

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
| `@display` | `EuiToolTipDisplay` |  | Display of the anchor wrapper: `'inlineBlock'` or `'block'`. |
| `@delay` | `ToolTipDelay` | `'regular'` | Delay before showing: `'regular'` (250ms) or `'long'` (for repeated items). |
| `@title` | `string` |  | An optional title for your tooltip. |
| `@id` | `string` |  | Unless you provide one, this will be randomly generated. |
| `@position` | `ToolTipPositions` | `'top'` | Suggested position: `'top'`, `'right'`, `'bottom'` or `'left'`. If there is not enough room for it this will be changed. |
| `@attachTo` | `undefined \| HTMLElement \| string \| null` |  | Shows the tooltip for another element (or selector) instead of the `<:anchor>` block's content. |
| `@isShown` | `boolean \| undefined` |  | Shows (`true`) or hides (`false`) the tooltip from outside. |
| `@onMouseOut` | `(event: MouseEvent) => void` |  | If supplied, called when mouse movement causes the tool tip to be hidden. |
| `@onFocus` | `() => void` |  | Called when the anchor gets focus. |
| `@onBlur` | `() => void` |  | Called when the anchor loses focus. |
| `@hasTitle` | `boolean` | `true` | Render the title. |

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
| `@type` | `string` | `'questionInCircle'` | The icon. |
| `@color` | `string` |  | Color of the icon, any `EuiIcon` color. |
| `@size` |  |  | Size of the icon. |
| `@ariaLabel` | `string` | "Info" | Accessible name of the icon. |
| `@anchorClassName` | `string` |  | Class for the element wrapping the icon. |
| `@onMouseOut` | `(event: MouseEvent) => void` |  | Called when the pointer leaves the icon. |
| `@display` |  |  | Display of the wrapper: `'inlineBlock'` or `'block'`. |

| Block | Description |
| --- | --- |
| `<:content>` | The tooltip's content, instead of `@content`. |
| `<:title>` | The tooltip's title, instead of `@title`. |

</EuiText>
<!-- api:end -->
