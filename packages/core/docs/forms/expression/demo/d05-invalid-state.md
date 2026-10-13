---
order: 5
---

# Invalid state

<EuiText>

Set `@isInvalid` to true to display `EuiExpression`'s error state. This state will override the `@color` argument with danger.

</EuiText>

```gjs component
import { EuiExpression, EuiSpacer } from '@ember-eui/core/components';

const noop = () => {};

<template>
  <div>
    <EuiExpression
      @onClick={{noop}}
      @description="sort by"
      @value="count"
      @isInvalid={{true}}
    />
    <EuiSpacer />
    <div style="max-width: 220px">
      <EuiExpression
        @description="email"
        @display="columns"
        @isInvalid={{true}}
        @value="example@mail."
        @onClick={{noop}}
      />
    </div>
  </div>
</template>
```
