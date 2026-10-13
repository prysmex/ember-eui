---
order: 2
---

# Colors

<EuiText>

You can pass a `@color` argument but it will only color the `@description`.

</EuiText>

```gjs component
import { EuiExpression, EuiSpacer } from '@ember-eui/core/components';

<template>
  <div>
    <EuiExpression @description="Success" @value="isDefault()" />
    <EuiSpacer @size="s" />
    <EuiExpression @description="Primary" @value="color()" @color="primary" />
    <EuiSpacer @size="s" />
    <EuiExpression @description="accent" @value="color()" @color="accent" />
    <EuiSpacer @size="s" />
    <EuiExpression @description="warning" @value="color()" @color="warning" />
    <EuiSpacer @size="s" />
    <EuiExpression @description="danger" @value="color()" @color="danger" />
    <EuiSpacer @size="s" />
    <EuiExpression @description="subdued" @value="color()" @color="subdued" />
    <EuiSpacer @size="s" />
    <EuiExpression
      @description="active"
      @value="state will get color() as well"
      @color="accent"
      @isActive={{true}}
    />
  </div>
</template>
```
