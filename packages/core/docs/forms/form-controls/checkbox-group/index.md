---
order: 2
title: Checkbox group
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Checkbox group"/>

<EuiSpacer />

<EuiText>
  <p>
    This component is different yet simplier from what you'd expect in ember in a way that you don't control the rendering of each checkbox, you just pass in an array of <EuiCode>@options</EuiCode> and <EuiCode>@idToSelectedMap</EuiCode> which you are in charge to calculate on subsequent <EuiCode>@onChange</EuiCode>'s, refer to the javascript snippet.
  </p>
  <p>
  You can optionally pass <EuiCode>@valueKey</EuiCode> and <EuiCode>@labelKey</EuiCode> for a more flexible and ergonomic API, so you don't actually have to map your options to
    <EuiCode>{ id: '', label: '' }</EuiCode> which are the default <EuiCode>@valueKey</EuiCode> and <EuiCode>@labelKey</EuiCode>.
  </p>
  <p>
    When the individual labels for each radio do not provide a
    sufficient description, pass a <EuiCode>@legend</EuiCode> to the
    group.
  </p>
  <p>
    Use the <EuiCode>@compressed</EuiCode> prop to tighten up the spacing
    between checkbox rows.
  </p>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCheckboxGroup

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@valueKey` | `string` | `'id'`; pass `'value'` for options shaped like `{ value, label }` | Key of each option holding its id, used with `@idToSelectedMap` and passed to `@onChange`. |
| `@labelKey` | `string` | `'label'` | Key of each option holding its label. |
| `@isInvalid` | `boolean` |  | Marks the group invalid for native form validation (e.g. EuiForm's `checkValidity()`). |
| `@legend` |  |  | Wraps the checkboxes in an `EuiFormFieldset` with this legend, e.g. "Choose toppings". Use it when the group is not inside an `EuiFormRow`. |
| `@compressed` |  |  | Smaller checkboxes, for dense forms. |
| `@options` (required) |  |  | The checkboxes: `[{ id: 'a', label: 'Option A' }, …]` (keys set by `@valueKey` / `@labelKey`). `disabled` and `className` apply to one checkbox. |
| `@formId` | `string` |  | `form` attribute of the checkboxes, to join a form by id. |
| `@disabled` |  |  | Disables every checkbox. |
| `@onChange` (required) | `(value: any) => void` |  | Called with the id (`@valueKey` value) of the checkbox that changed, then the change event. Toggle it in `@idToSelectedMap` here. |
| `@idToSelectedMap` (required) | `Record<string, boolean>` |  | Checked state by option id: `{ a: true, b: false }`. |

Deprecated: `@label` (Has no effect; use `@legend` or an `EuiFormRow` label.).

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
