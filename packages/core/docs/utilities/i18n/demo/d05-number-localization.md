---
order: 5
---

# Number localization

<EuiText>

<strong>EuiI18nNumber</strong> can be used to format one or more numbers. Similarly to <strong>EuiI18n</strong>, it takes <EuiCode>@value</EuiCode> or <EuiCode>@values</EuiCode> and can render directly to the DOM or yield the formatted text to a block.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiI18nNumber } from '@ember-eui/core/components';

<template>
<p>
  Formatted count of users:
  <EuiI18nNumber @value={{5000000}} />
</p>
</template>
```
