---
order: 5
---

# Justify and align

<EuiText>

`EuiFlexGroup` has the args `@justifyContent` and `@alignItems` that accept [normal flexbox parameters](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Flexible_Box_Layout/Aligning_Items_in_a_Flex_Container). Below are some common scenarios, where you need to separate two items, center justify a single one, or center an item vertically. Note the usage of `EuiFlexItem`s with `@grow={{false}}` so that they do not stretch.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiHorizontalRule } from '@ember-eui/core/components';

<template>
  <EuiFlexGroup class="flex-demo" @justifyContent="spaceAround">
    <EuiFlexItem @grow={{false}}>I&rsquo;m a single centered item!</EuiFlexItem>
  </EuiFlexGroup>

  <EuiHorizontalRule />

  <EuiFlexGroup class="flex-demo" @justifyContent="spaceBetween">
    <EuiFlexItem @grow={{false}}>One here on the left.</EuiFlexItem>
    <EuiFlexItem @grow={{false}}>The other over here on the right.</EuiFlexItem>
  </EuiFlexGroup>

  <EuiHorizontalRule />

  <EuiFlexGroup class="flex-demo" @justifyContent="spaceEvenly">
    <EuiFlexItem @grow={{false}}>Spaced evenly between this one.</EuiFlexItem>
    <EuiFlexItem @grow={{false}}>And this one here on the right.</EuiFlexItem>
  </EuiFlexGroup>

  <EuiHorizontalRule />

  <EuiFlexGroup class="flex-demo" @alignItems="center">
    <EuiFlexItem @grow={{false}}>
      <p>I</p>
      <p>am</p>
      <p>a</p>
      <p>tall</p>
      <p>item</p>
    </EuiFlexItem>
    <EuiFlexItem>I am vertically centered!</EuiFlexItem>
  </EuiFlexGroup>
</template>
```
