---
order: 4
---

# Inline

<EuiText>

Inline forms can be made with `EuiFlexGroup`. Apply `@grow={{false}}` on any of the items you want to collapse (like the button below). Note that the button's `EuiFormRow` wrapper also requires an additional argument when it's missing a label: `@hasEmptyLabelSpace`.

</EuiText>

```gjs component
import {
  EuiButton,
  EuiFieldText,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
} from '@ember-eui/core/components';

<template>
  <EuiFlexGroup style="max-width: 600px">
    <EuiFlexItem>
      <EuiFormRow @label="First name" @helpText="I am helpful help text!">
        <EuiFieldText />
      </EuiFormRow>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiFormRow @label="Last name">
        <EuiFieldText />
      </EuiFormRow>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiFormRow @hasEmptyLabelSpace={{true}}>
        <EuiButton>Save</EuiButton>
      </EuiFormRow>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
