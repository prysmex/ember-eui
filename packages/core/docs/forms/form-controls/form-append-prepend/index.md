---
title: Form append and prepend
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Form append and prepend"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiFormPrepend` and `EuiFormAppend` render content joined to the start or
end of a form control: a label, icons and/or a button. Put them in the
`<:prepend>` / `<:append>` blocks of a field (`EuiFieldText`,
`EuiFieldNumber`, `EuiSelect`, …) or of an `EuiFormControlLayout`.

They inherit `@compressed`, the disabled state and the control id from the
surrounding layout: a static label is a `<label>` for the control, and an
`@onClick` (or `@element="button"`) renders a `<button>`.

### Arguments (`EuiFormAppendPrependArgs`)

| Argument | Type | Description |
| --- | --- | --- |
| `@label` | `string` | Main text: a `<label>` for the control, or the button text. |
| `@iconLeft` / `@iconRight` | `EuiIcon` type | Icons before / after the label. |
| `@element` | `'div' \| 'button'` | Defaults to `'button'` with `@onClick`, `'div'` otherwise. |
| `@onClick` | `(event) => void` | Click handler; renders a `<button>`. |
| `@inputId` | `string` | Id the label points to; defaults to the layout's `@inputId`. |
| `@id` | `string` | Id of the label element. |
| `@compressed` | `boolean` | Defaults to the layout's `@compressed`. |
| `@isDisabled` / `@disabled` | `boolean` | Disables the button; a static node also follows the layout. |
| `@css` | `EuiCss` | Extra styles composed last into the root class. |

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFormPrepend

Also takes the args of `EuiFormAppendPrependArgs`.

| Block | Description |
| --- | --- |
| default block | Content after the label and icons. |

### EuiFormAppend

Also takes the args of `EuiFormAppendPrependArgs`.

| Block | Description |
| --- | --- |
| default block | Content after the label and icons. |

</EuiText>
<!-- api:end -->
