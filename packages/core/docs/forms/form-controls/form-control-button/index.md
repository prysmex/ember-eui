---
title: Form control button
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Form control button"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiFormControlButton` is a button that looks like a form control, for
example to open a picker or a popover from a form row. `@value` is shown
like an input value (and is the `<button>`'s `value`); `@placeholder` is
shown while there is none. Inside an `EuiFormControlLayout` it follows the
layout's `@compressed`, `@isInvalid`, disabled and read-only states.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFormControlButton

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@value` | `string` |  | Text shown like an input value. It is also the `<button>`'s `value`. |
| `@placeholder` | `string` |  | Text shown (in the placeholder color) while there is no `@value`. |
| `@compressed` | `boolean` | the surrounding `EuiFormControlLayout`'s `@compressed` | Shorter control. |
| `@isInvalid` | `boolean` | the surrounding `EuiFormControlLayout`'s `@isInvalid` | Invalid styling. |
| `@fullWidth` | `boolean` | `true` (upstream) | Stretches to the container's width. |
| `@isDisabled` | `boolean` | the surrounding `EuiFormControlLayout`'s disabled state | Disables the button. |
| `@isLoading` | `boolean` |  | Shows a spinner on the right and disables the button (not shown when the surrounding layout already shows its own spinner). |
| `@iconType` |  |  | Icon next to the text; anything `EuiIcon`'s `@type` accepts. |
| `@iconSide` | `'left' \| 'right'` | the left side | `'right'` puts the icon after the text. |
| `@iconSize` |  | `'m'` | Size of the icon. |
| `@href` | `string` |  | Renders an `<a>` link instead of a `<button>`. |
| `@target` | `string` |  | `target` of the `@href` link. |
| `@type` | `string` | `'button'` | `type` of the `<button>`. |
| `@contentCss` | `EuiCss` |  | Extra styles composed last into the content element's class (upstream `contentProps.css`). |
| `@textCss` | `EuiCss` |  | Extra styles composed last into the value/placeholder text's class (upstream `textProps.css`). |
| `@css` | `EuiCss` |  | Extra styles composed last into this component's class (like upstream's `css` prop). Prefer this to an extra class when styling it from a parent. |

| Block | Description |
| --- | --- |
| default block | Content after the value/placeholder text, e.g. a badge. |

</EuiText>
<!-- api:end -->
