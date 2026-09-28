---
order: 0
title: Form layouts
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Form layouts"/>
<EuiSpacer @size="l" />

<EuiText>

Forms are built from **form rows**: `EuiFormRow` wraps one control (a text
field, a select, a group of radios, …) with its label, help text and error
messages, and links the label to the control for you.

```hbs
<EuiForm @tagName="form" {{on "submit" this.save}}>
  <EuiFormRow @label="Email" @helpText="We never share it.">
    <EuiFieldText @value={{this.email}} {{on "input" this.updateEmail}} />
  </EuiFormRow>

  <EuiButton @type="submit" @fill={{true}}>Save</EuiButton>
</EuiForm>
```

- **`EuiForm`** wraps the rows and can list the form's errors in a callout
  (`@isInvalid` and `@error`). With `@tagName="form"` it renders a `<form>`.
- **`EuiFormRow`** takes `@label`, `@helpText`, and `@error` (shown while
  `@isInvalid`). `@display` switches between a stacked label (`row`), a
  compressed variant and a label beside the control (`columnCompressed`).
- **`EuiFormFieldset`** groups related controls under a legend.
- **`EuiDescribedFormGroup`** gives a section of a long form a title and a
  description on the left.

EUI's controls do not keep their own value: pass `@value` (or `@checked`)
and update it from the change event, as in the examples below.

For validation, `@ember-eui/validated-form` and
`@ember-eui/changeset-form` build on these components.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiForm

Wraps a form's rows and shows its errors in a callout. For validation
built on it see `@ember-eui/changeset-form` and
`@ember-eui/validated-form`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@errorTitle` | `string` | "Please correct the fields" | Title of the errors callout. |
| `@invalidCallout` | `'above' \| 'none'` | `'above'` | `'above'` shows `@error` in a callout above the form while `@isInvalid`; `'none'` hides it. |
| `@error` | `string \| string[]` |  | The form's errors, listed in the callout: an array of messages, or a single message with `@array={{true}}`. |
| `@isInvalid` | `boolean` |  | Shows the errors callout (with `@error`). |
| `@array` | `boolean` |  | Treats a single string `@error` as a one-item list. |
| `@tagName` | `'form' \| 'div'` | `'div'` | `'form'` renders a `<form>` (add `{{on "submit" …}}`); `'div'` for forms without native submission. |

| Block | Description |
| --- | --- |
| default block | The form's content, usually `EuiFormRow`s and a submit button. |
| `<:content>` | Same as the default block. |
| `<:error>` | Renders each error in the callout; yields the error. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<form>`.

### EuiFormRow

A form control with its label, help text and errors:
`<EuiFormRow @label="Name" @helpText="As shown to others"><EuiFieldText … /></EuiFormRow>`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@label` | `string` |  | The control's label. It is linked to the first text-like control in the row automatically (no need to pass ids around). |
| `@labelAppend` | `string` |  | Text at the end of the label line, e.g. "Optional". Use the `<:labelAppend>` block for markup such as a help link. |
| `@labelType` | `'label' \| 'legend'` | `'label'` | `'label'` renders a `<label>`; `'legend'` a `<legend>`, for rows whose control is a group (radios, checkboxes). |
| `@legendType` | `'legend' \| 'fieldset'` | a `<div>` | `'legend'` renders the row as a `<fieldset>` (use it with `@labelType="legend"` for groups). |
| `@fullWidth` | `boolean` |  | Lets the row (and its control) take the container's full width. |
| `@isInvalid` | `boolean` |  | Shows `@error` under the control and styles the label as invalid. |
| `@isDisabled` | `boolean` |  | Disables the label's focus styling. |
| `@hasEmptyLabelSpace` | `boolean` |  | Adds space above the control as if it had a label, to align it with labelled rows next to it (e.g. a button in an `EuiFlexGroup` of rows). |
| `@hasChildLabel` | `boolean` | `true` | Link the label to the control. Set `false` when the control has its own label (e.g. a single checkbox). |
| `@helpText` | `string` |  | Help text under the control (a string, or an array for several lines). The control's `aria-describedby` points to it, so screen readers read it with the control. |
| `@error` | `string \| string[] \| null` |  | Error message(s) shown under the control while `@isInvalid`; they are added to the control's `aria-describedby` while shown. |
| `@errorClasses` | `string` |  | Extra classes for each error message. |
| `@helpTextClasses` | `string` |  | Extra classes for the help text. |
| `@id` | `string` | a random id | Id of the control; the label points to it. |
| `@display` |  | `'row'` | Layout: `'row'` (label above), `'rowCompressed'`, `'columnCompressed'` (label beside, for dense forms), `'columnCompressedSwitch'` (for an `EuiSwitch`), or `'center'` / `'centerCompressed'` (vertically centers a control without a label, e.g. a button next to rows). |

Deprecated: `@extra` (Has no effect.).

| Block | Description |
| --- | --- |
| default block | The control, e.g. `<EuiFieldText />`. |
| `<:label>` | Custom label content, instead of `@label`; yields `@label`. |
| `<:field>` | The control; same as the default block. |
| `<:errors>` | Renders each error (while `@isInvalid`); yields the error. |
| `<:helpText>` | Custom help text, instead of `@helpText`. |
| `<:labelAppend>` | Content at the end of the label line, e.g. a help link. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>` / `<fieldset>`.

### EuiFormFieldset

Groups related controls (e.g. radios) under a legend.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@legend` | `string` |  | The legend describing the group. Use the `<:legend>` block for markup. |
| `@compressed` | `boolean` |  | Smaller legend, for compressed forms. |
| `@display` |  | `'visible'` | `'hidden'` keeps the legend for screen readers only. |

| Block | Description |
| --- | --- |
| default block | The controls. |
| `<:legend>` | The legend, instead of `@legend`. |
| `<:fieldset>` | The controls; same as the default block. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<fieldset>`.

### EuiFormLegend

The legend of an EuiFormFieldset.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@display` | `'hidden' \| 'visible'` | `'visible'` | `'hidden'` keeps it for screen readers only. |
| `@compressed` | `boolean` |  | Smaller legend, for compressed forms. |

| Block | Description |
| --- | --- |
| default block | The legend text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<legend>`.

### EuiFormLabel

The label of a control; EuiFormRow renders it from `@label`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isFocused` | `boolean` |  | Focused styling (the control has focus). |
| `@isInvalid` | `boolean` |  | Invalid styling. |
| `@type` | `'legend' \| 'label'` | `'label'` | `'label'` renders a `<label>`, `'legend'` a `<legend>` (for fieldsets). |
| `@for` | `string` |  | Id of the control it labels. |
| `@label` | `string` |  | The label text, before the block content. |

| Block | Description |
| --- | --- |
| default block | The label text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<label>` / `<legend>`.

### EuiFormHelpText

Help text under a control; EuiFormRow renders it from `@helpText`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` |  | Id, to reference from the control's `aria-describedby`. |

| Block | Description |
| --- | --- |
| default block | The text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiFormErrorText

An error message under a control; EuiFormRow renders these from `@error`.

| Block | Description |
| --- | --- |
| default block | The message. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->
