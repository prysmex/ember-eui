---
order: 4
---

# Empty pages or content

<EuiText>

When the content is in an empty/pre-setup state, we recommend then using an [`EuiEmptyPrompt`](/docs/core/docs/display/empty-prompt) to direct users on next steps. Using `T.EmptyPrompt` will automatically center the prompt vertically and horizontally. Its default block is the prompt's body.

The prompt's panel color depends on the other configurations but can be manually passed in via the `@color` arg.

</EuiText>

```gjs component
import { EuiPageTemplate, EuiSkeletonText, EuiButton } from '@ember-eui/core/components';

<template>
  <EuiPageTemplate
    @panelled={{true}}
    @restrictWidth={{false}}
    @bottomBorder={{true}}
    @offset={{0}}
    @grow={{false}}
  >
    <:sidebar as |T|>
      <T.Sidebar>
        <EuiSkeletonText @isLoading={{true}} @lines={{8}} />
      </T.Sidebar>
    </:sidebar>
    <:default as |T|>
      <T.Header @iconType="logoElastic" @pageTitle="Page title">
        <:rightSideItems as |Item|>
          <Item><EuiButton>Right side item</EuiButton></Item>
        </:rightSideItems>
      </T.Header>
      <T.EmptyPrompt>
        <:title><span>No spice</span></:title>
        <:default>
          <EuiSkeletonText @isLoading={{true}} @lines={{3}} />
        </:default>
        <:footer><EuiButton>Footer action</EuiButton></:footer>
      </T.EmptyPrompt>
    </:default>
  </EuiPageTemplate>
</template>
```
