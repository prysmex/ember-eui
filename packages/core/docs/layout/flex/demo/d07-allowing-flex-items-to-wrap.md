---
order: 7
---

# Allowing flex items to wrap

<EuiText>

You can set `@wrap={{true}}` on `EuiFlexGroup` if it contains `EuiFlexItem`s with minimum widths, which you want to wrap as the container becomes narrower.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';

<template>
  <EuiFlexGroup class="flex-demo" @wrap={{true}}>
    <EuiFlexItem style="min-width: 300px">Min-width 300px</EuiFlexItem>

    <EuiFlexItem style="min-width: 300px">Min-width 300px</EuiFlexItem>

    <EuiFlexItem style="min-width: 300px">Min-width 300px</EuiFlexItem>
  </EuiFlexGroup>
</template>
```
