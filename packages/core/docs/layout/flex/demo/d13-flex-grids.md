---
order: 13
---

# Flex grids

<EuiText>

`EuiFlexGrid` is a more rigid component, used for repeatable rows of same-width items. You can set a `@columns` arg to specify anywhere between 1-4 columns. Any more would likely break on laptop screens.

</EuiText>

```gjs component
import { EuiFlexGrid, EuiFlexItem } from '@ember-eui/core/components';

<template>
  <EuiFlexGrid class="flex-demo" @columns={{3}}>
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
