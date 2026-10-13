---
order: 2
---

# Text sizes

<EuiText>

Match the text size of **EuiHealth** to your context by passing `xs / s / m / inherit` to the `@textSize` argument. The `inherit` style will get its font size from the parent element.

</EuiText>

```gjs component
import { EuiHealth, EuiSpacer, EuiTitle } from '@ember-eui/core/components';

<template>
<div>
  <EuiHealth @textSize="xs" @color="success">Extra small</EuiHealth>
  <EuiSpacer />
  <EuiHealth @textSize="s" @color="success">Small (Default)</EuiHealth>
  <EuiSpacer />
  <EuiHealth @textSize="m" @color="success">Medium</EuiHealth>
  <EuiSpacer />
  <EuiTitle @size="s">
    <h3>
      <EuiHealth @textSize="inherit" @color="success">Inherit</EuiHealth>
    </h3>
  </EuiTitle>
</div>
</template>
```
