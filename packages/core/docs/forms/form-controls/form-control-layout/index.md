---
title: Form control layout
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Form control layout"/>

<EuiSpacer />

<EuiText>
  <p>
    <EuiBadge @color="warning">Building block only</EuiBadge>
  </p>
  <p>
    <strong>EuiFormControlLayout</strong> is generally used internally
    to consistently style form controls, but it's published in
    case you want to create your own form control which matches those of
    EUI.
  </p>
  <EuiCallOut @title="Additional padding required" @color="warning">
    <:body>
      <p>
      The padding on the <EuiCode>input</EuiCode> itself doesn't
      take into account the presence of the various icons supported by
      <strong>EuiFormControlLayout</strong>. Any input component
      provided to <strong>EuiFormControlLayout</strong> is responsible
      for its own padding.
      </p>
    </:body>
  </EuiCallOut>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFormControlLayout

The wrapper EUI's inputs use for icons, the clear button, the loading
spinner and prepend/append content. Use it around your own controls to
match them.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@fullWidth` | `boolean` |  | Stretches the control to its container's width. |
| `@compressed` | `boolean` |  | Shorter control, for dense forms. |
| `@readOnly` | `boolean` |  | Read-only styling. |
| `@useGroup` | `boolean` | `true` | Styles the control as a group with its `<:prepend>` / `<:append>` content. |
| `@disabled` | `boolean` |  | Disabled styling. |
| `@isDisabled` | `boolean` |  | Same as `@disabled`. |
| `@icon` |  |  | Icon inside the control, anything `EuiIcon`'s `@type` accepts. |
| `@iconSide` |  | `'left'` | Side of `@icon`: `'left'` or `'right'`. |
| `@clear` |  |  | Shows a clear ("x") button calling this function. |
| `@isLoading` | `boolean` |  | Shows a spinner. |

Deprecated: `@inputId` (Has no effect.).

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the control; yields the class to put on it. |
| `<:field>` | The control (e.g. an `<input>`); same as the default block. |
| default block | The control. |
| `<:append>` | Content after the control; yields the class to put on it. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
