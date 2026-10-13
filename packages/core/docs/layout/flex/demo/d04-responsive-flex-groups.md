---
order: 4
---

# Responsive flex groups

<EuiText>

`EuiFlexGroup` is responsive by default, stacking items vertically on smaller screens. If you need to disable this behavior (e.g. for groups only used for alignment and margins rather than layouts), apply `@responsive={{false}}` to retain a single row layout at all screen sizes.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiIcon, EuiSpacer } from '@ember-eui/core/components';

<template>
  <EuiFlexGroup class="flex-demo" @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <EuiIcon @type="faceSad" />
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      On mobile, the icon will show above this text.
    </EuiFlexItem>
  </EuiFlexGroup>

  <EuiSpacer />

  <EuiFlexGroup class="flex-demo" @responsive={{false}} @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <EuiIcon @type="faceHappy" />
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      On mobile, the icon will stay to the left of this text.
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
