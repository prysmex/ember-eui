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

A checkbox: a styled square over a visually hidden native
`<input type="checkbox">`. Attributes and modifiers (`value`,
`{{on "change" …}}`) go to the `<input>`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@checked` | `boolean` |  | Whether it is checked. Update it from `{{on "change" …}}`. |
| `@disabled` | `boolean` |  | Disables the checkbox. |
| `@readOnly` | `boolean` |  | Makes the checkbox read-only: it keeps its checked state, shows a default cursor and does not change colours on focus. Native `readonly` does not stop checkboxes from toggling, so clicks are cancelled (what React's controlled input does upstream when the state is not updated). |
| `@indeterminate` | `boolean` |  | Shows the "partially checked" state, e.g. for a "select all" box. Sets the input's `indeterminate` property. |
| `@label` | `string` |  | Label next to the checkbox. Use the `<:label>` block for markup. |
| `@labelProps` | `{ className?: string; }` |  | Props for the `<label>`: `{ className }`. |
| `@containerClass` | `string` |  | Extra classes for the wrapper around the input and label. |
| `@className` | `string` |  | Extra classes for the wrapper around the input and label. |
| `@inputRef` | `(element: HTMLInputElement) => void` |  | Called with the `<input>` element once rendered. |
| `@id` | `string` | a random id | Id of the input, linked to the label. |
| `@name` | `string` |  | `name` of the input, for forms. |
| `@css` | `EuiCss` |  | Extra styles composed last into the wrapper's class (like upstream's `css` prop, which lands on the wrapper too). Prefer this to `@containerClass` when styling it from a parent. |

Deprecated: `@icon` (Has no effect; upstream EUI has no icon variant.); `@compressed` (Has no effect on a single checkbox (upstream EUI has no compressed checkbox). `EuiCheckboxGroup`'s `@compressed` tightens the spacing between rows.).

| Block | Description |
| --- | --- |
| `<:label>` | The label, instead of `@label`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
