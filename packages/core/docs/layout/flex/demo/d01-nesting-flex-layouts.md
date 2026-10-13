---
order: 1
---

# Nesting flex layouts

<EuiText>

`EuiFlexGroup` and `EuiFlexGrid` can nest within themselves indefinitely. For example, here we turn off the growth on a `EuiFlexGroup`, then nest a grid inside of it.

<EuiCallOut @title="Flex items are also a flexbox" @color="warning" @iconType="warning" @size="s">
  <p>To support nested stretching of items, <strong>EuiFlexItem</strong> also has <code>display: flex</code> on it. If your children are not behaving correctly, consider using one of the flex item workarounds in "Flex items are also flex" below.</p>
</EuiCallOut>

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiFlexGrid } from '@ember-eui/core/components';

<template>
  <EuiFlexGroup class="flex-demo">
    <EuiFlexItem @grow={{false}}>
      <div>Flex Group</div>
      <EuiSpacer />
      <EuiFlexGroup>
        <EuiFlexItem>Nested Group One</EuiFlexItem>
        <EuiFlexItem>Nested Group Two</EuiFlexItem>
      </EuiFlexGroup>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <div>Flex Grid</div>
      <EuiSpacer />
      <EuiFlexGrid @columns={{3}}>
        <EuiFlexItem>Nested Grid One</EuiFlexItem>
        <EuiFlexItem>Nested Grid Two</EuiFlexItem>
        <EuiFlexItem>Nested Grid Three</EuiFlexItem>
        <EuiFlexItem>Nested Grid Four</EuiFlexItem>
      </EuiFlexGrid>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
