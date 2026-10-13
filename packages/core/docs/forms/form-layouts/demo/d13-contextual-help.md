---
order: 13
---

# Contextual help

<EuiText>

When using compressed, horizontal form styles, it is best not to overload the UI with expansive help text. If it's short and part of the validation, use `@helpText`. However, if it's an explanation of the control, consider wrapping the label with an `EuiToolTip` and appending the `question` icon to it.

</EuiText>

```gjs component
import {
  EuiFieldText,
  EuiFormRow,
  EuiIcon,
  EuiPanel,
  EuiSelect,
  EuiToolTip,
} from '@ember-eui/core/components';

const selectOptions = [
  { value: 'option_one', text: 'Option one' },
  { value: 'option_two', text: 'Option two' },
  { value: 'option_three', text: 'Option three' },
];

<template>
  <EuiPanel style="max-width: 300px">
    <EuiFormRow
      @label="Text field"
      @helpText="Show validation help text only."
      @display="columnCompressed"
    >
      <EuiFieldText name="first" @compressed={{true}} />
    </EuiFormRow>

    <EuiFormRow @display="columnCompressed">
      <:label>
        <EuiToolTip @content="Otherwise use an EuiToolTip around the label of the form row.">
          <span>Label <EuiIcon @type="question" @color="subdued" /></span>
        </EuiToolTip>
      </:label>
      <:field>
        <EuiSelect @options={{selectOptions}} @compressed={{true}} />
      </:field>
    </EuiFormRow>
  </EuiPanel>
</template>
```
