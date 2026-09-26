---
order: 1
title: Checkbox
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Checkbox"/>

<EuiSpacer />

<EuiText>
  <p>
    This component renders a basic HTML <EuiCode @language="html">{{'<input type="checkbox">'}}</EuiCode> element.
    Use checkboxes to allow users to select multiple options from a list.
  </p>
  <p>
    Use the <EuiCode>@checked</EuiCode> argument to handle the checked and
    unchecked state. You can also use the <EuiCode>@indeterminate</EuiCode> argument to set an indeterminate state.
    This state is commonly used in hierarchical checkboxes to indicate that only some of the checkbox's descendants are checked.
  </p>
  <p>
    Make sure to pass a <EuiCode>@label</EuiCode> to ensure a larger
    clickable area and ensure that screen readers will read out the
    label when the user is focused on the input.
    You can also use the <EuiCode>:label</EuiCode> block for a more complex label.
  </p>
</EuiText>

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiCheckbox

Attributes and modifiers (`value`, `{{on "change" …}}`) go to the
`<input type="checkbox">`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@checked` | `boolean` |  | Whether it is checked. Update it from `{{on "change" …}}`. |
| `@disabled` | `boolean` |  | Disables the checkbox. |
| `@indeterminate` | `boolean` |  | Shows the "partially checked" state, e.g. for a "select all" box. |
| `@compressed` | `boolean` |  | Smaller checkbox, for dense forms. |
| `@label` | `string` |  | Label next to the checkbox. Use the `<:label>` block for markup. |
| `@labelProps` | `{ className?: string; }` |  | Props for the `<label>`: `{ className }`. |
| `@containerClass` | `string` |  | Extra classes for the wrapper around the input and label. |
| `@className` | `string` |  | Extra classes for the wrapper around the input and label. |
| `@inputRef` | `(element: HTMLInputElement) => void` |  | Called with the `<input>` element once rendered. |
| `@id` | `string` | a random id | Id of the input, linked to the label. |
| `@name` | `string` |  | `name` of the input, for forms. |

| Block | Description |
| --- | --- |
| `<:label>` | The label, instead of `@label`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
