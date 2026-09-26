---
order: 1
title: Checkbox
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Checkbox"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiCheckbox` renders an `<input type="checkbox">` with its label. Use a
checkbox for one yes/no choice that applies when the form is submitted
(for settings that apply immediately, prefer `EuiSwitch`); for several
related choices, use `EuiCheckboxGroup`.

```hbs
<EuiCheckbox
  @label="Remember me"
  @checked={{this.remember}}
  {{on "change" this.toggleRemember}}
/>
```

Pass `@checked` and update it from the `change` event
(`event.target.checked`). Always give it a `@label` (or the `<:label>`
block): the label is clickable and read by screen readers.
`@indeterminate` shows a "partially checked" state, e.g. for a "select all"
checkbox when only some items are selected.

</EuiText>

<EuiHorizontalRule />

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
