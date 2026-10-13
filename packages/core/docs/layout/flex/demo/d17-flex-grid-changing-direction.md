---
order: 17
---

# Changing direction

<EuiText>

Adding `@direction="column"` will re-orient the flex items so they display top-down **then** left to right.

</EuiText>

```gjs component
import { EuiFlexGrid, EuiFlexItem } from '@ember-eui/core/components';

<template>
  <EuiFlexGrid class="flex-demo" @columns={{2}} @direction="column">
    <EuiFlexItem>One</EuiFlexItem>
    <EuiFlexItem>Two</EuiFlexItem>
    <EuiFlexItem>Three</EuiFlexItem>
    <EuiFlexItem>Four</EuiFlexItem>
    <EuiFlexItem>Five</EuiFlexItem>
    <EuiFlexItem>Six</EuiFlexItem>
    <EuiFlexItem>Seven</EuiFlexItem>
  </EuiFlexGrid>
</template>
```
