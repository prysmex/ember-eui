---
title: Form control layout delimited
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Form control layout delimited"/>

<EuiSpacer />

<EuiText>
  <p>
    <EuiBadge @color="warning">Building block only</EuiBadge>
  </p>

  <p>
    Like <strong>EuiFormControlLayout</strong>,
    <strong>EuiFormControlLayoutDelimited</strong> is generally used
    internally to consistently style form controls. This component
    specifically lays out two form controls with center text or icon.
  </p>
  <p>
    It requires both a <EuiCode>:startControl</EuiCode> and a <EuiCode>:endControl</EuiCode> block.
    You can optionally change the center content to a different string or node (like an EuiIcon).
  </p>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFormControlLayoutDelimited

Two controls in one field with a delimiter between them, e.g. a number
range ("0 → 100") or start and end dates.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@icon` | `string` |  | Icon at the start of the control, anything `EuiIcon`'s `@type` accepts. |
| `@clear` |  |  | Shows a clear ("x") button calling this function. |
| `@fullWidth` |  |  | Stretches the control to its container's width. |
| `@isLoading` |  |  | Shows a spinner. |
| `@compressed` |  |  | Shorter control, for dense forms. |
| `@readOnly` |  |  | Read-only styling. |
| `@disabled` |  |  | Disabled styling. |
| `@delimiter` | `string` | `'→'` | Text between the two controls. |
| `@useGroup` | `boolean` | `true` | Styles it as a group with `<:prepend>` / `<:append>`. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the controls; yields the class to put on it. |
| `<:startControl>` | The first control, e.g. an `EuiFieldNumber @controlOnly={{true}}`; yields the class to put on it. |
| `<:delimiter>` | Custom delimiter content, instead of `@delimiter`. |
| `<:endControl>` | The second control; yields the class to put on it. |
| `<:append>` | Content after the controls; yields the class to put on it. |

</EuiText>
<!-- api:end -->
