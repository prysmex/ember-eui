---
order: 6
---

# Truncate text

<EuiText>

To truncate `EuiExpression`'s content, pass `@textWrap="truncate"`. Text truncation only works properly if `@description` and `@value` are strings. If you're using blocks, use the `.eui-textTruncate` utility class on all their sub-children.

</EuiText>

```gjs component
import { EuiExpression, EuiSpacer, EuiTitle } from '@ember-eui/core/components';

const noop = () => {};
const value = 'and a very long string as value';
const description = 'some very very long description';

<template>
  <div>
    <div style="max-width: 240px">
      <EuiExpression
        @onClick={{noop}}
        @description={{description}}
        @value={{value}}
        @textWrap="truncate"
      />
      <EuiSpacer />
      <EuiExpression
        @description={{description}}
        @display="columns"
        @textWrap="truncate"
        @value={{value}}
        @onClick={{noop}}
      />
      <EuiSpacer />
    </div>
    <EuiTitle @size="xxs">
      <h3>eui-textTruncate applied to sub-children</h3>
    </EuiTitle>
    <div style="max-width: 310px">
      <EuiExpression
        @display="columns"
        @textWrap="truncate"
        @description="indices"
        @onClick={{noop}}
      >
        <:value>
          <p class="eui-textTruncate">.kibana_task_manager</p>
          <p class="eui-textTruncate">kibana_sample_data_ecommerce</p>
        </:value>
      </EuiExpression>
    </div>
  </div>
</template>
```
