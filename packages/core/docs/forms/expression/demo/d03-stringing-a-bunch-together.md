---
order: 3
---

# Stringing a bunch together

<EuiText>

If the expression is more than one description and value, you can string multiple expressions together and they should inline together and wrap at logical points.

</EuiText>

```gjs component
import { EuiExpression } from '@ember-eui/core/components';

const noop = () => {};

<template>
  <div>
    <EuiExpression @description="Select" @value="count(*)" @onClick={{noop}} />
    <EuiExpression
      @description="From"
      @value="kibana_sample_data_ky_counties left"
    />
    <EuiExpression
      @description="join"
      @value="kibana_sample_data_ky_avl right"
      @onClick={{noop}}
    />
    <EuiExpression @description="on" @value="left.smis = right.kytccountynmbr" />
    <EuiExpression
      @description="group by"
      @value="right.kytccountynmbr"
      @onClick={{noop}}
      @color="accent"
    />
    <EuiExpression @description="sort by" @value="count" />
  </div>
</template>
```
