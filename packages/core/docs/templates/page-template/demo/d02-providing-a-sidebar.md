---
order: 2
---

# Providing a sidebar

<EuiText>

If your application requires the use of side navigation or other sidebar content, render a `T.Sidebar` containing your sidebar content in the template's `<:sidebar as |T|>` block. The template will automatically adjust the layout when a sidebar is rendered: the content becomes panelled, gets a border, and the header's bottom border stays within the content.

Pass `@sticky={{true}}` to make the sidebar stick to the top of the browser window and scroll independently of the rest of the layout. If you have any fixed [`EuiHeader`s](/docs/core/docs/layout/header), these will be accounted for as well.

Typically when a sidebar is included and `@restrictWidth` is defined, we recommend keeping `@bottomBorder={{true}}`, though you can also expand particular sections with `@bottomBorder="extended"`.

</EuiText>

<EuiSpacer />

<EuiCallOut @size="s" @color="warning" @title="Sidebars go in the sidebar block">
  <p>Upstream finds its sidebars among the template's direct children. In Ember, render <code>T.Sidebar</code> in the <code>&lt;:sidebar&gt;</code> block, which is placed beside the main content; it may be conditional. Rendering it in the default block is an error.</p>
</EuiCallOut>

```gjs component
import { EuiPageTemplate, EuiText, EuiButton, EuiSkeletonText } from '@ember-eui/core/components';

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
      <T.Section @grow={{false}} @bottomBorder={{true}}>
        <EuiText @textAlign="center">
          <strong>
            Stack EuiPageTemplate sections and headers to create your custom content order.
          </strong>
        </EuiText>
      </T.Section>
      <T.Section>
        <EuiSkeletonText @isLoading={{true}} @lines={{6}} />
      </T.Section>
    </:default>
  </EuiPageTemplate>
</template>
```
