---
order: 10
---

# Panels grow vertically to fill flex items

<EuiText>

The `EuiPanel` component will naturally grow to fill the `EuiFlexItem` which contains it.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiText, EuiCode, EuiPanel } from '@ember-eui/core/components';

<template>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiText>
        <p>
          <EuiCode>FlexItem</EuiCode>
        </p>
        <p>A side nav might be in this one.</p>
        <p>And you would want the panel on the right to expand with it.</p>
      </EuiText>
    </EuiFlexItem>

    <EuiFlexItem>
      <EuiPanel>
        <strong>EuiPanel</strong>
      </EuiPanel>
    </EuiFlexItem>

    <EuiFlexItem>
      <EuiPanel @grow={{false}}>
        Another <strong>EuiPanel</strong>, with
        <EuiCode>@grow=&#123;&#123;false&#125;&#125;</EuiCode>.
      </EuiPanel>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
