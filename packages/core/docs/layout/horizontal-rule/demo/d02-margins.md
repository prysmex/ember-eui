---
order: 2
---

# Margins

<EuiText>

The spacing added before and after `EuiHorizontalRule` can be adjusted using the `@margin` arg. Don’t forget that margins will collapse against items that proceed and/or follow.

</EuiText>

```gjs component
import { EuiCode, EuiHorizontalRule } from '@ember-eui/core/components';

<template>
  <div class="horizontal-rule-demo">
    <EuiCode>none</EuiCode>
    <div>
      <EuiHorizontalRule @margin="none" />
    </div>
    <EuiCode>xs</EuiCode>
    <div>
      <EuiHorizontalRule @margin="xs" />
    </div>
    <EuiCode>s</EuiCode>
    <div>
      <EuiHorizontalRule @margin="s" />
    </div>
    <EuiCode>m (default)</EuiCode>
    <div>
      <EuiHorizontalRule @margin="m" />
    </div>
    <EuiCode>l</EuiCode>
    <div>
      <EuiHorizontalRule @margin="l" />
    </div>
    <EuiCode>xl</EuiCode>
    <div>
      <EuiHorizontalRule @margin="xl" />
    </div>
    <EuiCode>xxl</EuiCode>
    <div>
      <EuiHorizontalRule @margin="xxl" />
    </div>
  </div>
</template>
```
