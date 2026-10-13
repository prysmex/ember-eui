---
order: 10
---

# Limit the use of shadows

<EuiText>
  <p>
Shadows are great for drawing focus to a single layer of a page. But if everything has a shadow it becomes too noisy. Use shadows sparingly and try to use them at either the top or bottom of the stack.
  </p>
</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiPanel, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';

<template>
  <EuiSpacer @size='l' />
  <EuiFlexGroup @gutterSize='m'>
    <EuiFlexItem>
      <EuiText @size='s'><p><strong>Do:</strong> Minimize shadows within a panel stack by removing the shadows from all but a single layer.</p></EuiText>
      <EuiSpacer @size='s' />
      <EuiPanel @hasShadow={{false}} @hasBorder={{true}} style='transform: scale(.9);'>
        <EuiTitle @size='s'><span>Panel 1</span></EuiTitle>
        <EuiSpacer />
        <EuiPanel @color='subdued'>
          <EuiTitle @size='xs'><span>Panel 2</span></EuiTitle>
          <EuiSpacer />
          <EuiPanel style='min-height: 100px;'>
            <EuiTitle @size='xxs'><span>Panel 3</span></EuiTitle>
          </EuiPanel>
        </EuiPanel>
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiText @size='s'><p><strong>Don't:</strong> Stacking multiple shadowed panels is too noisy.</p></EuiText>
      <EuiSpacer @size='s' />
      <EuiPanel @hasShadow={{true}} @hasBorder={{false}} style='transform: scale(.9);'>
        <EuiTitle @size='s'><span>Panel 1</span></EuiTitle>
        <EuiSpacer />
        <EuiPanel @hasShadow={{true}} @hasBorder={{false}}>
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
