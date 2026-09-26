---
order: 2
title: Checkbox group
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Checkbox group"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiCheckboxGroup` renders a list of checkboxes from `@options`. You keep
which ones are checked in `@idToSelectedMap` (`{ [id]: true }`) and update
it in `@onChange`, which receives the id of the checkbox that changed.

```hbs
<EuiCheckboxGroup
  @options={{this.toppings}}
  @idToSelectedMap={{this.selected}}
  @onChange={{this.toggle}}
/>
```

```js
toppings = [{ id: 'cheese', label: 'Cheese' }, { id: 'olives', label: 'Olives' }];
@tracked selected = { cheese: true };

@action toggle(id) {
  this.selected = { ...this.selected, [id]: !this.selected[id] };
}
```

Options are `{ id, label }` by default; `@valueKey` and `@labelKey` read
other keys, so you can pass your own objects. Pass `@legend` when the group
is not inside an `EuiFormRow`, so it has a name.

</EuiText>

<EuiHorizontalRule />

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
