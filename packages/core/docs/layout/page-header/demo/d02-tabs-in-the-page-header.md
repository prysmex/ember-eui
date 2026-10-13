---
order: 2
---

# Tabs in the page header

<EuiText>

A set of `@tabs` can be displayed inside the page header by passing an array of tab objects using the `label` key for the tab content. When displaying tabs, `@bottomBorder` will be enforced to create separation of the header and content. You'll still need to manage the page content and selected tab in your own instance.

</EuiText>

```gjs component
import { EuiPageHeader, EuiButton } from '@ember-eui/core/components';
import { array, hash } from '@ember/helper';

<template>
  <EuiPageHeader
    @pageTitle="Page title"
    @tabs={{array (hash label="Tab 1" isSelected=true) (hash label="Tab 2")}}
  >
    <:rightSideItems as |Item|>
      <Item>
        <EuiButton @fill={{true}}>Add something</EuiButton>
      </Item>
      <Item>
        <EuiButton>Do something</EuiButton>
      </Item>
    </:rightSideItems>
  </EuiPageHeader>
</template>
```
