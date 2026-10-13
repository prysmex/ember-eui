---
order: 3
---

# Custom label

<EuiText>

The `<:label>` block takes markup instead of `@label`.

</EuiText>

```gjs component
import { EuiRadio, EuiBadge } from '@ember-eui/core/components';

<template>
  <EuiRadio @name="shipping" @checked={{true}}>
    <:label>
      Express <EuiBadge @color="success">Free</EuiBadge>
    </:label>
  </EuiRadio>
</template>
```
