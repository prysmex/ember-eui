---
order: 1
---

# Component

<EuiText>

Pass an illustration asset to the `@type` argument. The component picks the correct color-mode variant automatically, so try toggling the theme in the top toolbar.

</EuiText>

```gjs component
import { EuiIllustration } from '@ember-eui/core/components';
import { dashboard } from '@elastic/eui-illustrations';

<template>
  <div style="max-inline-size: 360px">
    <EuiIllustration @type={{dashboard}} />
  </div>
</template>
```

