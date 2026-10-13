---
order: 3
---

# Chart

<EuiText>

To indicate that a visualization is loading, use **EuiLoadingChart**.

</EuiText>

```gjs component
import { EuiLoadingChart } from '@ember-eui/core/components';

<template>
<div>
  <EuiLoadingChart @size="m" />
  &nbsp;&nbsp;
  <EuiLoadingChart @size="l" />
  &nbsp;&nbsp;
  <EuiLoadingChart @size="xl" />
  &nbsp;&nbsp;
  <EuiLoadingChart @size="xl" @mono={{true}} />
</div>
</template>
```
