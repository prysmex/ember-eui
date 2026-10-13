---
order: 8
---

# Nesting three or more panels

<EuiText>
  <p>
If the same style panel is used between multiple nested panels, the hierarchy can be visually confusing and the benefit of panels breaks down. While there is no hard and fast rule in which sequence of panels styles should be used, varying the styles will help guide the user through the content relationship.
  </p>
</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiPanel, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';

<template>
  <EuiSpacer @size='l' />
  <EuiFlexGroup @gutterSize='m'>
    <EuiFlexItem>
      <EuiText @size='s'><p><strong>Do:</strong> Break up stacked panel styles with different style combinations.</p></EuiText>
      <EuiSpacer @size='s' />
      <EuiPanel @hasShadow={{true}} @hasBorder={{false}} style='transform: scale(.9);'>
        <EuiTitle @size='s'><span>Panel 1</span></EuiTitle>
        <EuiSpacer />
        <EuiPanel @color='subdued'>
          <EuiTitle @size='xs'><span>Panel 2</span></EuiTitle>
          <EuiSpacer />
          <EuiPanel @hasShadow={{false}} @hasBorder={{true}} style='min-height: 100px;'>
            <EuiTitle @size='xxs'><span>Panel 3</span></EuiTitle>
          </EuiPanel>
        </EuiPanel>
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiText @size='s'><p><strong>Don't:</strong> Too many of same panel style in a stack of panels (3+ deep) isn't helpful.</p></EuiText>
      <EuiSpacer @size='s' />
      <EuiPanel @hasShadow={{false}} @hasBorder={{true}} style='transform: scale(.9);'>
        <EuiTitle @size='s'><span>Panel 1</span></EuiTitle>
        <EuiSpacer />
        <EuiPanel @hasShadow={{false}} @hasBorder={{true}}>
          <EuiTitle @size='xs'><span>Panel 2</span></EuiTitle>
          <EuiSpacer />
          <EuiPanel @hasShadow={{false}} @hasBorder={{true}} style='min-height: 100px;'>
            <EuiTitle @size='xxs'><span>Panel 3</span></EuiTitle>
          </EuiPanel>
        </EuiPanel>
      </EuiPanel>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
