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
| `@iconSide` |  | `'left'` | Side of `@icon`: `'left'` or `'right'` (upstream `icon.side`). |
| `@clear` |  |  | Shows a clear ("x") button calling this function. |
| `@fullWidth` |  |  | Stretches the control to its container's width. |
| `@isLoading` |  |  | Shows a spinner. |
| `@compressed` |  |  | Shorter control, for dense forms. |
| `@readOnly` |  |  | Read-only styling. |
| `@disabled` |  |  | Disabled styling. |
| `@isDisabled` |  |  | Same as `@disabled`. |
| `@isInvalid` | `boolean` |  | Invalid styling: a danger underline/border, a danger delimiter and the warning icon (not while disabled or read-only). |
| `@delimiter` | `string` | upstream's `sortRight` arrow icon, labelled "to" for screen readers (`euiFormControlLayoutDelimited.delimiterLabel`) | Text between the two controls. |
| `@isPrependProvided` | `boolean` | `true` | Renders the `<:prepend>` block. Lets a wrapper that always passes the block hide it without remounting the layout (upstream passes `prepend={undefined}`). |
| `@isAppendProvided` | `boolean` | `true` | Renders the `<:append>` block. Lets a wrapper that always passes the block hide it without remounting the layout (upstream passes `append={undefined}`). |

Deprecated: `@useGroup` (Has no effect: the delimited layout is always a group.).

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the controls; yields the class to put on it. |
| `<:startControl>` | The first control, e.g. an `EuiFieldNumber @controlOnly={{true}}`; yields the class to put on it (it carries the delimited input styles). |
| `<:delimiter>` | Custom delimiter content, instead of `@delimiter`. |
| `<:endControl>` | The second control; yields the class to put on it. |
| `<:append>` | Content after the controls; yields the class to put on it. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
