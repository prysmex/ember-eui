---
order: 4
---

# Empty pages or content

<EuiText>

When the content is in an empty/pre-setup state, we recommend then using an `EuiEmptyPrompt` to direct users on next steps. Upstream's `EuiPageTemplate.EmptyPrompt` centers the prompt vertically and horizontally; here `@template="centeredContent"` does that for an `EuiEmptyPrompt` placed in the default block.

The prompt's panel color depends on the other configurations but can be manually passed in via the `@color` arg.

</EuiText>

```gjs component
import { EuiPageTemplate, EuiSkeletonText, EuiButton, EuiEmptyPrompt, EuiTitle, EuiSpacer } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

<template>
  <EuiPageTemplate
    @template="centeredContent"
    @grow={{false}}
    @restrictWidth={{false}}
    @pageHeader={{hash iconType="logoElastic" pageTitle="Page title"}}
  >
    <:pageSideBar><EuiSkeletonText @isLoading={{true}} @lines={{8}} /></:pageSideBar>
    <:pageHeaderRightSideItems as |Item|>
      <Item><EuiButton>Right side item</EuiButton></Item>
    </:pageHeaderRightSideItems>
    <:default>
      <EuiEmptyPrompt @title="No spice" @paddingSize="l">
        <:content>
          <EuiTitle @size="m"><h2>No spice</h2></EuiTitle>
          <EuiSpacer />
          <EuiSkeletonText @isLoading={{true}} @lines={{3}} />
        </:content>
        <:footer><EuiButton>Footer action</EuiButton></:footer>
      </EuiEmptyPrompt>
    </:default>
  </EuiPageTemplate>
</template>
```
