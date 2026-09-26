---
order: 3
title: Radio
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Radio"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiRadio` renders one `<input type="radio">` with its label. Radios with
the same `@name` form a group: selecting one deselects the others. Most of
the time `EuiRadioGroup`, which renders the whole group from options, is
simpler; use single radios when each one needs custom layout.

```hbs
<EuiRadio
  @name="plan"
  @label="Monthly"
  @checked={{eq this.plan "monthly"}}
  {{on "change" (fn this.choose "monthly")}}
/>
```

Use radios for 2 to about 6 options that should all be visible; for more,
use `EuiSelect` or `EuiComboBox`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiRadio

A single radio. Attributes and modifiers (`value`, `{{on "change" …}}`)
go to the `<input type="radio">`. For a list of choices use
EuiRadioGroup.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@checked` | `boolean` |  | Whether it is checked. |
| `@disabled` | `boolean` |  | Disables the radio. |
| `@name` | `string` |  | `name` of the radio; radios with the same name form a group. |
| `@label` | `string` |  | Label next to the radio. Use the `<:label>` block for markup. |
| `@labelProps` | `{ className?: string; }` |  | Props for the `<label>`: `{ className }`. |
| `@compressed` | `boolean` |  | Smaller radio, for dense forms. |
| `@containerClass` | `string` |  | Extra classes for the wrapper around the input and label. |
| `@inputRef` | `(element: HTMLInputElement \| null) => void` |  | Called with the `<input>` element once rendered. |
| `@id` | `string` | a random id | Id of the input, linked to the label. |

| Block | Description |
| --- | --- |
| `<:label>` | The label, instead of `@label`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<input>`.

</EuiText>
<!-- api:end -->
