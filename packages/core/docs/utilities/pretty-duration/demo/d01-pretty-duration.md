---
order: 1
---

# Pretty duration

```gjs component
import { EuiDescriptionList, EuiPrettyDuration } from '@ember-eui/core/components';

const items = [
  { from: 'now-15m', to: 'now' },
  { from: 'now', to: 'now+2d/d' },
  { from: 'now/d', to: 'now/d' },
  { from: '2018-01-17T18:57:57.149Z', to: '2018-01-18T18:57:57.149Z' }
];

<template>
  <EuiDescriptionList @type='column'>
    {{#each items as |item|}}
      <dt>{{item.from}} to {{item.to}}</dt>
      <dd><EuiPrettyDuration @timeFrom={{item.from}} @timeTo={{item.to}} @dateFormat='MMM D, YYYY' /></dd>
    {{/each}}
  </EuiDescriptionList>
</template>
```
