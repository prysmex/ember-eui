---
order: 3
title: Radio
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Radio"/>

<EuiSpacer />

<EuiText>
  <p>
    This component renders a basic HTML <EuiCode @language="html">{{'<input type="radio">'}}</EuiCode> element.
    Use radio buttons to allow users to choose one option out of a list.
    They are ideal for a list of more than 2 options, and usually no more than 6 options.
  </p>
  <p>
    When creating a list, each input should have the same <EuiCode>@name</EuiCode> to ensure a group is established.
    This way when you select a radio button in that group, the other options are automatically deselected.
  </p>
  <p>
    Make sure to pass a <EuiCode>@label</EuiCode> to ensure a larger clickable area and ensure that screen readers will read out the label when the user is focused on the input.
    You can also use the <EuiCode>:label</EuiCode> block for a more complex label.
  </p>
</EuiText>

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
