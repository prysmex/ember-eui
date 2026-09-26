---
title: Radio group
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="Radio group"/>

<EuiSpacer />

<EuiText>
  <p>
    This component is different yet simplier from what you'd expect in ember in a way that you don't control the rendering of each checkbox, you just pass in an array of <EuiCode>@options</EuiCode> and <EuiCode>@idSelected</EuiCode> which you are in charge to calculate on subsequent <EuiCode>@onChange</EuiCode>'s, refer to the javascript snippet.
  </p>

  <p>
    You can optionally pass <EuiCode>@valueKey</EuiCode> and <EuiCode>@labelKey</EuiCode> for a more flexible and ergonomic API, so you don't actually have to map your options to
    <EuiCode>{ id: '', label: '' }</EuiCode> which are the default <EuiCode>@valueKey</EuiCode> and <EuiCode>@labelKey</EuiCode>.
  </p>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiRadioGroup

A group of radios to pick one option.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@idSelected` (required) | `string` |  | Id (`@valueKey` value) of the checked option. |
| `@options` (required) |  |  | The radios: `[{ id: 'a', label: 'Option A' }, …]` (keys set by `@valueKey` / `@labelKey`); `value`, `disabled` and `className` are optional. |
| `@name` | `string` |  | `name` shared by the radios. |
| `@legend` | `string` |  | Wraps the radios in an `EuiFormFieldset` with this legend. Use it when the group is not inside an `EuiFormRow`. |
| `@compressed` | `boolean` |  | Smaller radios, for dense forms. |
| `@disabled` | `boolean` |  | Disables every radio. |
| `@onChange` (required) | `(id: string, value?: string) => void` |  | Called with the chosen option's id and its `value`. Update `@idSelected` here. |
| `@valueKey` | `string` | `'id'` | Key of each option holding its id. |
| `@labelKey` | `string` | `'label'` | Key of each option holding its label. |
| `@formId` | `string` |  | `form` attribute of the radios, to join a form by id. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
