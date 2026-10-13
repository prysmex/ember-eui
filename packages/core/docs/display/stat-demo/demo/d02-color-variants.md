---
order: 2
---

# Color variants

<EuiText>

`@title` can be altered using the `@titleColor` argument. By default, it will appear in `full` color. For proper color contrast, only a limited set of EUI colors are offered. See the API reference below for a list of available colors.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiStat } from '@ember-eui/core/components';

<template>
<EuiFlexGroup @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiStat @title="1" @description="Default color" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiStat @title="10" @description="Subdued color" @titleColor="subdued" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiStat @title="100" @description="Primary color" @titleColor="primary" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiStat @title="100,000" @description="Accent color" @titleColor="accent" />
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiFlexGroup @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiStat @title="1,000" @description="Success color" @titleColor="success" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiStat @title="1,000" @description="Warning color" @titleColor="warning" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiStat @title="10,000" @description="Danger color" @titleColor="danger" />
  </EuiFlexItem>
</EuiFlexGroup>
</template>
```
