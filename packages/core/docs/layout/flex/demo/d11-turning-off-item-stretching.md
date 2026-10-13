---
order: 11
---

# Turning off item stretching

<EuiText>

<EuiCallOut @title="Grow only applies to groups" @color="warning" @iconType="warning" @size="s">
  <p>The <code>@grow</code> arg of <strong>EuiFlexItem</strong> only applies when used within <strong>EuiFlexGroup</strong>. It is ignored by <strong>EuiFlexGrid</strong>, which enforces the same width for each item.</p>
</EuiCallOut>

By default, all `EuiFlexItem`s will grow horizontally within their flex group if the `@grow` arg is not specified. This can be turned off for each item individually via `@grow={{false}}`.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';

<template>
  <EuiFlexGroup class="flex-demo">
    <EuiFlexItem @grow={{false}}>This item won&rsquo;t grow</EuiFlexItem>
    <EuiFlexItem>But this item will.</EuiFlexItem>
  </EuiFlexGroup>
</template>
```
