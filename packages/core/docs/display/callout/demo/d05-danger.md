---
order: 5
---

# Danger

<EuiText>

Use this callout to let the user know that something went wrong. For example if you want to communicate an error. You should receive an error message when the issue is **terminal, this doesn't always mean that the operation stops completely, but the task is not complete**.

</EuiText>

```gjs component
import { EuiCallOut, EuiLink } from '@ember-eui/core/components';

<template>
<EuiCallOut @title="Sorry, there was an error" @color="danger">
  <p>
    Now you have to fix it, but maybe
    <EuiLink @href="#">this link can help</EuiLink>.
  </p>
</EuiCallOut>
</template>
```
