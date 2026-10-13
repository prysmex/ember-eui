---
order: 4
---

# Sizes

<EuiText>

You can adjust the `@size` of both determinate and indeterminate progress bars.

</EuiText>

```gjs component
import { EuiProgress, EuiSpacer } from '@ember-eui/core/components';

<template>
<div>
  <EuiProgress @value={{20}} @max={{100}} @size="xs" />
  <EuiSpacer @size="l" />

  <EuiProgress @value={{40}} @max={{100}} @size="xs" />
  <EuiSpacer @size="l" />

  <EuiProgress @value={{60}} @max={{100}} @size="s" />
  <EuiSpacer @size="l" />

  <EuiProgress @value={{80}} @max={{100}} @size="m" />
  <EuiSpacer @size="l" />

  <EuiProgress @value={{90}} @max={{100}} @size="l" />
</div>
</template>
```
