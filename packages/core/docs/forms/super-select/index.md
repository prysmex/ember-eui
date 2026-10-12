---
title: Super select
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Super select"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiSuperSelect` is a select whose options can show more than a line of
text: a title with a description, an icon, a color. For plain text
options prefer `EuiSelect`, which uses the native control.

```hbs
<EuiSuperSelect
  @options={{this.options}}
  @valueOfSelected={{this.value}}
  @onChange={{this.setValue}}
/>
```

Each option is `{ value, inputDisplay, dropdownDisplay, disabled }`:
`inputDisplay` is shown in the control once selected, `dropdownDisplay`
in the list (it defaults to `inputDisplay`). For markup, use the
`<:inputDisplay>` and `<:dropdownDisplay>` blocks, which yield the option.
`@onChange` gets the chosen option's `value`.

The list opens on click or with the up and down arrows; the arrows move
between options and Escape closes it. `@name` adds a hidden input with the
value, for forms.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSuperSelect

A select whose options can show more than text: a title with a
description, an icon, a color. Pick it over `EuiSelect` when options
need that; for plain text options `EuiSelect` is simpler and native.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@options` (required) | `EuiSuperSelectOption<any>[]` |  | The options: `{ value, inputDisplay, dropdownDisplay, disabled }`. Use the `<:inputDisplay>` / `<:dropdownDisplay>` blocks for markup. |
| `@valueOfSelected` | `unknown` |  | Value of the selected option. |
| `@placeholder` | `string` |  | Shown in the control while no option is selected. |
| `@onChange` | `(value: any) => void` |  | Called with the chosen option's value. |
| `@isOpen` | `boolean` |  | Opens the list (e.g. on first render). |
| `@isInvalid` | `boolean` |  | Invalid look and the warning icon. |
| `@isLoading` | `boolean` |  | Shows a spinner. |
| `@disabled` | `boolean` |  | Disables the control. |
| `@readOnly` | `boolean` |  | Read-only: shows the value, the list cannot be opened. |
| `@hasDividers` | `boolean` |  | Lines between the options, for options with several lines. Ember extension: latest EUI removed it. |
| `@fullWidth` | `boolean` |  | Takes the container's full width. |
| `@compressed` | `boolean` |  | Smaller, for dense forms. |
| `@itemClassName` | `string` |  | Extra classes for each option. |
| `@name` | `string` |  | `name` of the hidden input, for forms. |
| `@id` | `string` |  | `id` of the hidden input. Pass the same `@id` to the `EuiFormRow` so its label also labels the control. |
| `@onFocus` | `() => void` |  | Called when the list opens. |
| `@onBlur` | `() => void` |  | Called when the list closes. |

Deprecated: `@itemLayoutAlign` (Removed upstream. Aligns the check mark with the `'center'` (default), the `'top'` or the `'bottom'` of each option.).

| Block | Description |
| --- | --- |
| `<:inputDisplay>` | Renders the selected option in the control; yields it. |
| `<:dropdownDisplay>` | Renders an option in the list; yields it. |
| `<:prepend>` | Content before the control; yields the class to put on it. |
| `<:append>` | Content after the control; yields the class to put on it. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

### EuiSuperSelectControl

The button of an `EuiSuperSelect`, showing the selected option, with a
hidden `<input>` holding its value for forms. Usually rendered for you
by `EuiSuperSelect`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@options` | `EuiSuperSelectOption<unknown>[]` |  | The options, to show the selected one. |
| `@value` | `unknown` |  | Value of the selected option. |
| `@id` | `string` |  | `id` of the hidden input. When an element `<id>-label` exists (the label of an `EuiFormRow` given the same `@id`), the button is labelled by it and by its own value, as upstream. |
| `@name` | `string` |  | `name` of the hidden input, for forms. |
| `@placeholder` | `string` |  | Shown while no option is selected. |
| `@fullWidth` | `boolean` |  | Takes the container's full width. |
| `@compressed` | `boolean` |  | Smaller, for dense forms. |
| `@isLoading` | `boolean` |  | Shows a spinner. |
| `@isInvalid` | `boolean` |  | Invalid look and the warning icon. |
| `@disabled` | `boolean` |  | Disables the control. |
| `@readOnly` | `boolean` |  | Read-only: shows the value, cannot be opened. |
| `@isDropdownOpen` | `boolean` |  | Focus styles while the list is open (set by `EuiSuperSelect`). |

Deprecated: `@screenReaderId` (Has no effect: latest EUI no longer renders a separate screen reader announcement for the control.).

| Block | Description |
| --- | --- |
| `<:inputDisplay>` | Renders the selected option yourself; yields it. |
| `<:prepend>` | Content before the control; yields the class to put on it. |
| `<:append>` | Content after the control; yields the class to put on it. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

</EuiText>
<!-- api:end -->
