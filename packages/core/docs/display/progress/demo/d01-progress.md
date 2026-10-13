---
order: 1
---

# Progress

<EuiText>

The **EuiProgress** component by default will display in an indeterminate loading state (rendered as a single div) until you define a `@max` and `@value` argument. The `@size` argument refers to its vertical height. It will always stretch `100%` to its container.

</EuiText>

```gjs component
import { EuiProgress } from '@ember-eui/core/components';

<template>
<div>
  <EuiProgress @size="xs" @color="accent" />
</div>
</template>
```
