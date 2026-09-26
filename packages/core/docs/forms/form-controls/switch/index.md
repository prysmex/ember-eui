---
title: Switch
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Switch"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiSwitch` is an on/off toggle. Use it for settings that take effect
immediately, like "Show grid"; for choices submitted with a form, a
checkbox reads better.

```hbs
<EuiSwitch
  @label="Show grid"
  @checked={{this.showGrid}}
  @onChange={{this.toggleGrid}}
/>
```

`@onChange` receives the click event; `event.target.checked` is the new
state. The label describes what is turned on (not "on"/"off"). With
`@showLabel={{false}}` the label is only read by screen readers.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSwitch

An on/off toggle, for settings that apply immediately.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@id` | `string` | a random id | Id of the switch button. |
| `@showLabel` | `boolean` | `true` | Whether to render the text label. Without it `@label` becomes the accessible label. |
| `@label` | `string` |  | Must be a string if `showLabel` prop is true |
| `@checked` (required) | `boolean` |  | Whether it is on. |
| `@onChange` | `(event: MouseEvent) => void` |  | Called on click; `event.target.checked` is the new state. Update `@checked` here. |
| `@disabled` | `boolean` |  | Disables the switch. |
| `@compressed` | `boolean` |  | Smaller switch, for dense forms. |
| `@type` | `'submit' \| 'reset' \| 'button'` | `'button'` | `type` of the button. |
| `@containerClass` | `string` |  | Extra classes for the wrapper. |

| Block | Description |
| --- | --- |
| `<:label>` | The label, instead of `@label`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

</EuiText>
<!-- api:end -->
