---
order: 12
---

# Proportional widths of items

<EuiText>

Alternatively, you can specify a `@grow` number between 1 and 10 for each `EuiFlexItem` to take up a proportional percentage of the `EuiFlexGroup` it is in.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiSpacer } from '@ember-eui/core/components';

<template>
  <div>
    <EuiFlexGroup class="flex-demo">
      <EuiFlexItem @grow={{1}}>1</EuiFlexItem>
      <EuiFlexItem @grow={{2}}>
        2<br />
        wraps content if necessary
      </EuiFlexItem>
      <EuiFlexItem @grow={{3}}>
        3<br />
        expands_to_fit_if_content_cannot_wrap
      </EuiFlexItem>
      <EuiFlexItem @grow={{4}}>4</EuiFlexItem>
    </EuiFlexGroup>

    <EuiSpacer />

    <EuiFlexGroup class="flex-demo">
      <EuiFlexItem @grow={{6}}>6</EuiFlexItem>
      <EuiFlexItem @grow={{3}}>3</EuiFlexItem>
      <EuiFlexItem @grow={{1}}>1</EuiFlexItem>
      <EuiFlexItem @grow={{3}}>3</EuiFlexItem>
      <EuiFlexItem @grow={{6}}>6</EuiFlexItem>
    </EuiFlexGroup>
  </div>
</template>
```
