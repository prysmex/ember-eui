---
order: 9
---

# Do not overuse panels

<EuiText>
  <p>
It’s easy to fall into the thinking that everything needs a panel. Carefully consider why you need a panel and if too many elements are fighting for attention.
  </p>
</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiPanel, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';

<template>
  <EuiSpacer @size='l' />
  <EuiFlexGroup @gutterSize='m'>
    <EuiFlexItem>
      <EuiText @size='s'><p><strong>Do:</strong> Reserve panels for drawing attention to certain elements.</p></EuiText>
      <EuiSpacer @size='s' />
      <EuiPanel @color='subdued' @hasShadow={{false}} style='transform: scale(.9);'>
        <EuiTitle @size='s'><span>Panel 1</span></EuiTitle>
        <EuiSpacer @size='s' />
        <EuiTitle @size='xs'><span>Sub-heading</span></EuiTitle>
        <EuiSpacer />
        <EuiPanel style='min-height: 100px;'>
          <EuiTitle @size='xxs'><span>Panel 2</span></EuiTitle>
        </EuiPanel>
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiText @size='s'><p><strong>Do:</strong> Remove panel styles but keep the component purely for containment.</p></EuiText>
      <EuiSpacer @size='s' />
      <EuiPanel @color='subdued' @hasShadow={{false}} style='transform: scale(.9);'>
        <EuiTitle @size='s'><span>Panel 1</span></EuiTitle>
        <EuiSpacer @size='s' />
        <EuiPanel @color='transparent' @paddingSize='none'>
          <EuiTitle @size='xs'><span>Panel 2</span></EuiTitle>
          <EuiSpacer />
          <EuiPanel @hasShadow={{true}} @hasBorder={{false}} style='min-height: 100px;'>
            <EuiTitle @size='xxs'><span>Panel 3</span></EuiTitle>
          </EuiPanel>
        </EuiPanel>
      </EuiPanel>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
