---
order: 8
---

# Changing direction

<EuiText>

You can change direction using the `@direction` arg (`row`, `rowReverse`, `column` or `columnReverse`).

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';

<template>
  <EuiFlexGroup class="flex-demo" @direction="column">
    <EuiFlexItem>Flex item</EuiFlexItem>
    <EuiFlexItem>Another flex item</EuiFlexItem>
    <EuiFlexItem>Using the column direction</EuiFlexItem>
  </EuiFlexGroup>
</template>
```
