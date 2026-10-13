---
order: 3
---

# Disabled elements

<EuiText>

Natively `disabled` elements are removed from the tab order, which prevents keyboard users from focusing them and discovering the tooltip. For custom or non-EUI elements, use `aria-disabled="true"` instead of the native `disabled` attribute. This keeps the element focusable and accessible to keyboard users, while still conveying the disabled state to assistive technologies. You should set `pointer-events: none` to prevent mouse interactions.

</EuiText>

```gjs component
import { EuiButton, EuiFlexGroup, EuiFlexItem, EuiToolTip } from '@ember-eui/core/components';

<template>
<EuiFlexGroup @alignItems='center' @gutterSize='m'>
  <EuiFlexItem @grow={{false}}>
    <EuiToolTip @content='Fill in all required fields to save'>
      <EuiButton @isDisabled={{true}}>Save (disabled)</EuiButton>
    </EuiToolTip>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiToolTip @content='Fill in all required fields to save'>
      <button type='button' aria-disabled='true' style='pointer-events: none'>
        Save (native HTML)
      </button>
    </EuiToolTip>
  </EuiFlexItem>
</EuiFlexGroup>
</template>
```
