---
order: 18
---

# Overriding the output element

<EuiText>

Pass `@tagName` to **EuiFlexGroup**, **EuiFlexGrid** and **EuiFlexItem** to render any element (upstream's `component`), e.g. `"p"` or `"ul"`. Inside elements that only accept inline content (e.g. a `<button>`), pass `@tagName="span"` to both the group and its items.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';

<template>
  <button type="button">
    <EuiFlexGroup class="flex-demo" @tagName="span">
      <EuiFlexItem @tagName="span">
        These items are within a button
      </EuiFlexItem>

      <EuiFlexItem @tagName="span">
        So they all specify @tagName=&ldquo;span&rdquo;
      </EuiFlexItem>
    </EuiFlexGroup>
  </button>
</template>
```
