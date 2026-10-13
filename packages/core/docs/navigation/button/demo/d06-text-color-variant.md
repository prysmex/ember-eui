---
order: 6
---

# Text color variant

<EuiText>

Use `text` button color variants on action-heavy UIs to reduce visual noise. This variant has a **unique bordered appearance** for dense screens with many inputs, buttons, and tabular content, where shaded buttons would create visual clutter.

</EuiText>

```gjs component
import { EuiButton, EuiButtonIcon, EuiFlexGroup, EuiFlexItem, EuiToolTip } from '@ember-eui/core/components';

<template>
<EuiFlexGroup @responsive={{false}} @gutterSize="s" @alignItems="flexStart">
  <EuiFlexItem @grow={{false}}>
    <EuiButton @color="text">Text color button</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiToolTip @content="Edit" @disableScreenReaderOutput={{true}}>
      <EuiButtonIcon @color="text" @display="base" @iconType="pencil" @size="m" aria-label="Edit" />
    </EuiToolTip>
  </EuiFlexItem>
</EuiFlexGroup>
</template>
```
