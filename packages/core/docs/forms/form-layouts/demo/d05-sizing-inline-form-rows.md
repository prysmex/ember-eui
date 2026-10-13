---
order: 5
---

# Sizing inline form rows

<EuiText>

Apply a `width` or change the `@grow` argument on the wrapping `EuiFlexItem` to size individual controls. When you need to make a field smaller, always apply the width to the flex item, not the input. The input inside will resize as needed.

When supplying children to an `EuiFormRow` that is **not** a form control, and you need the content to vertically center with the other form controls, change the `@display` argument to `center` or `centerCompressed`.

</EuiText>

```gjs component
import {
  EuiAvatar,
  EuiButton,
  EuiFieldNumber,
  EuiFieldText,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
} from '@ember-eui/core/components';

<template>
  <EuiFlexGroup style="max-width: 600px">
    <EuiFlexItem @grow={{false}} style="width: 100px">
      <EuiFormRow @label="Age">
        <EuiFieldNumber @max={{10}} placeholder="42" />
      </EuiFormRow>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiFormRow @label="Full name">
        <EuiFieldText @icon="user" placeholder="John Doe" />
      </EuiFormRow>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiFormRow @label="Avatar" @display="center">
        <EuiAvatar @name="John Doe" @size="s" />
      </EuiFormRow>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiFormRow @hasEmptyLabelSpace={{true}} @display="center">
        <EuiButton>Save</EuiButton>
      </EuiFormRow>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
