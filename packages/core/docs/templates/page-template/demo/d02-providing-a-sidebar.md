---
order: 2
---

# Providing a sidebar

<EuiText>

If your application requires the use of side navigation or other sidebar content, fill the `<:pageSideBar>` block with your sidebar content. The template will automatically adjust the layout when this content is provided.

The sidebar sticks to the top of the browser window and scrolls independently of the rest of the layout. If you have any fixed `EuiHeader`s, these will be accounted for as well. You can turn this behavior off with `@pageSideBarProps={{hash sticky=false}}`.

Typically when a sidebar is included and `@restrictWidth` is defined, we recommend keeping the `bottomBorder` of the page header.

</EuiText>

```gjs component
import { EuiPageTemplate, EuiSkeletonText, EuiButton, EuiText, EuiSpacer } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

<template>
  <EuiPageTemplate @grow={{false}} @restrictWidth={{false}} @pageHeader={{hash iconType="logoElastic" pageTitle="Page title"}}>
    <:pageSideBar>
      <EuiSkeletonText @isLoading={{true}} @lines={{8}} />
    </:pageSideBar>
    <:pageHeaderRightSideItems as |Item|>
      <Item><EuiButton>Right side item</EuiButton></Item>
    </:pageHeaderRightSideItems>
    <:default>
      <EuiText @textAlign="center">
        <strong>
          Stack EuiPageTemplate sections and headers to create your custom content order.
        </strong>
      </EuiText>
      <EuiSpacer />
      <EuiSkeletonText @isLoading={{true}} @lines={{6}} />
    </:default>
  </EuiPageTemplate>
</template>
```
