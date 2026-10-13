---
order: 4
---

# Warning

<EuiText>

Use this callout to warn the user against decisions they might regret. You should receive a warning message when the program detects that **something is not behaving right, but it didn't cause any termination**.

</EuiText>

```gjs component
import { EuiCallOut, EuiLink } from '@ember-eui/core/components';

<template>
<EuiCallOut @title="Proceed with caution!" @color="warning">
  <p>
    Here be dragons. Don&rsquo;t wanna mess with no dragons. And
    <EuiLink @href="#">here&rsquo;s a link</EuiLink>.
  </p>
</EuiCallOut>
</template>
```
