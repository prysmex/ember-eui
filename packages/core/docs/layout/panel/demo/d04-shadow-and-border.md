---
order: 4
---

# Shadow and border

<EuiText>
  <p>
By default, <strong>EuiPanel</strong> is flat with <EuiCode>@hasBorder=\{{true}}</EuiCode> on and <EuiCode>@hasShadow=\{{false}}</EuiCode>. Use <EuiCode>@hasShadow</EuiCode> when you need elevation. Be mindful of not using too many nested panels with these settings.
  </p>
</EuiText>

<EuiSpacer @size='m' />

<EuiCallOut @title='Certain allowed combinations of shadow, border, and color depend on the current theme.' @color='warning'>
  <p>
    For instance, only plain or transparent panels can have a border and/or shadow. The default theme doesn't allow combining the <EuiCode>@hasBorder</EuiCode> option with <EuiCode>@hasShadow</EuiCode>.
  </p>
</EuiCallOut>

```gjs component
import { EuiCode, EuiPanel, EuiSpacer } from '@ember-eui/core/components';

<template>
  <EuiSpacer @size='l' />
  <EuiPanel>
    <EuiCode>Default (hasBorder, no shadow)</EuiCode>
  </EuiPanel>

  <EuiSpacer />

  <EuiPanel @hasBorder={{false}} @hasShadow={{true}}>
    <EuiCode>@hasBorder=\{{false}} @hasShadow</EuiCode>
  </EuiPanel>
</template>
```
