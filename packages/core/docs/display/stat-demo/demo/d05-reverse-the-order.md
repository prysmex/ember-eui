---
order: 5
---

# Reverse the order

<EuiText>

You can reverse the order of the `@description` and `@title` text by setting the `@reverse` argument to true. By default, the description (label) is displayed above the title (value).

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiStat } from '@ember-eui/core/components';

<template>
<div>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiStat @title="10,000" @description="Description underneath" @reverse={{true}} />
    </EuiFlexItem>
  </EuiFlexGroup>
</div>
</template>
```
