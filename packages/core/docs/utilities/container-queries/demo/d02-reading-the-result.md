---
order: 2
---

# Reading the result

<EuiText>

Drag the bottom right corner of the box to resize it. <strong>EuiContainerQuery</strong> yields whether the container is wider than 400px.

</EuiText>

```gjs component
import { EuiCallOut, EuiContainerQuery, EuiSpacer } from '@ember-eui/core/components';

<template>
  <EuiSpacer />
  <div style='resize: horizontal; overflow: auto; inline-size: 500px; max-inline-size: 100%; border: 1px solid #98a2b3; padding: 8px;'>
    <EuiContainerQuery @condition='(width > 400px)' as |wide|>
      <EuiCallOut
        @title={{if wide 'Wide container' 'Narrow container'}}
        @color={{if wide 'success' 'warning'}}
      />
    </EuiContainerQuery>
  </div>
</template>
```
