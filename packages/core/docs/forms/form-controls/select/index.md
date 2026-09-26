---
title: Select
---
<EuiSpacer/>
<EuiPageHeader @pageTitle="Select"/>

<EuiSpacer />

<EuiText>
  <p>
    This component renders a basic HTML <EuiCode @language="html">{{'<select>'}}</EuiCode> element.
    Use <strong>EuiSelect</strong> to allow users to choose from a list of 7 to 12 options.
    When there are less than 7 options consider using a <strong>EuiRadioGroup</strong>.
  </p>
  <p>
    If you need more customization for how the options and/or selected values render, you can use an <strong>EuiSuperSelect</strong> instead.
    For long lists of options use an <strong>EuiComboBox</strong>, which has search and multi-select capabilities, but also has restrictions on how items are rendered.
  </p>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSelect

A native `<select>` styled like EUI's inputs. For search or multiple values use EuiComboBox.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the select. |
| `@options` (required) |  |  | The options: `[{ value: 'a', text: 'Option A', disabled? }]`. |
| `@value` | `string \| number` |  | The selected option's `value`. Update it from `{{on "change" …}}`. |
| `@fullWidth` | `boolean` |  | Stretches the select to its container's width. |
| `@compressed` | `boolean` |  | Shorter select, for dense forms. |
| `@isLoading` | `boolean` |  | Shows a spinner. |
| `@disabled` | `boolean` |  | Disables the select. |
| `@hasNoInitialSelection` | `boolean` | `false` | Adds an empty first option, selected while `@value` is empty, so no option is preselected. |
| `@isInvalid` | `boolean` |  | Shows the invalid state and marks it invalid for native form validation. |
| `@clear` | `(v: any) => void` |  | Shows a clear ("x") button calling this function. |
| `@inputRef` | `(element: HTMLSelectElement) => void` |  | Called with the `<select>` element once rendered. |

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the select; yields the class to put on it and the id. |
| `<:append>` | Content after the select; yields the class to put on it and the id. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<select>`.

</EuiText>
<!-- api:end -->
