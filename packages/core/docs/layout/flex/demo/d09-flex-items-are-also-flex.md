---
order: 9
---

# Flex items are also flex

<EuiText>

<EuiCallOut @title="Flex items must be direct children" @color="warning" @iconType="warning" @size="s">
  <p>To work correctly, <strong>EuiFlexItem</strong> must be a <strong>direct child</strong> of <strong>EuiFlexGroup</strong> or <strong>EuiFlexGrid</strong>. You cannot have any intermediate HTML wrappers between them.</p>
</EuiCallOut>

To allow for continued stretching of nested flex groups/grids and their items, each `EuiFlexItem` also has the property of `display: flex`.

This can sometimes cause unwanted layouts of your content when there are multiple elements, or if the element itself also has some specific `display` property. To alleviate this, the simplest method is to wrap your inner children with a HTML wrapper like a `<div />` or `<span />`.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiButton, EuiSpacer, EuiText, EuiPanel } from '@ember-eui/core/components';

<template>
  <EuiFlexGroup class="flex-demo">
    <EuiFlexItem>
      <EuiButton @fill={{true}}>Buttons will widen</EuiButton>
    </EuiFlexItem>
    <EuiFlexItem>
      <div>
        <EuiButton @fill={{true}}>Unless you wrap them</EuiButton>
      </div>
    </EuiFlexItem>
  </EuiFlexGroup>

  <EuiSpacer />

  <EuiText>

  Alternatively, you can sometimes opt to omit `EuiFlexItem` completely.

  </EuiText>

  <EuiSpacer />

  <EuiFlexGroup @justifyContent="spaceBetween" @alignItems="center">
    <EuiPanel @grow={{false}}>
      Flex group parents will still <br /> align children as usual
    </EuiPanel>
    <EuiButton @fill={{true}}>Look ma, no EuiFlexItem</EuiButton>
  </EuiFlexGroup>
</template>
```
