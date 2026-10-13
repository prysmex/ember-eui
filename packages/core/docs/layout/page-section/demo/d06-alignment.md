---
order: 6
---

# Alignment (Ember EUI extra)

<EuiText>

`@alignment="center"` centers the content in both directions inside a
section that grows (here in a 240px high flex column);
`'horizontalCenter'` only centers it horizontally.

</EuiText>

```gjs component
import { EuiPageSection, EuiEmptyPrompt } from '@ember-eui/core/components';

<template>
  <div style="display: flex; flex-direction: column; height: 240px; border: 1px dashed #98A2B3">
    <EuiPageSection @grow={{true}} @alignment="center" @color="subdued">
      <EuiEmptyPrompt @iconType="search" @title="No results" />
    </EuiPageSection>
  </div>
</template>
```
