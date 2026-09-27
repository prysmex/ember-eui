---
title: Radio group
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="Radio group"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiRadioGroup` renders a group of radios from `@options` (`{ id, label }`)
and checks the one whose id is `@idSelected`. `@onChange` receives the
chosen id (and the option's `value`): set `@idSelected` there.

```hbs
<EuiRadioGroup
  @options={{this.plans}}
  @idSelected={{this.plan}}
  @name="plan"
  @onChange={{this.choosePlan}}
/>
```

`@valueKey` and `@labelKey` read other keys of your options. Pass `@legend`
when the group is not inside an `EuiFormRow`. For a compact inline choice,
see `EuiButtonGroup`.

</EuiText>

<EuiHorizontalRule />

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
| `@name` | `string` | a random name | `name` shared by the radios. |
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
