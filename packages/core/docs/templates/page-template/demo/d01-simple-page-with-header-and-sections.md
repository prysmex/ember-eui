---
order: 1
---

# Simple page with header and sections

<EuiText>

`EuiPageTemplate` is for creating the different types of page layout patterns described in these docs. It is somewhat opinionated, but still has the ability to customize most of the inner components directly through args.

Upstream builds pages from namespaced children (`EuiPageTemplate.Section`, `.Header`, `.Sidebar`, `.BottomBar`, `.EmptyPrompt`) stacked in the order they are passed. Ember EUI instead has named blocks (`<:pageSideBar>`, `<:bottomBar>`, `<:default>`, …) and the `@template` arg. To stack your own sections and headers like upstream, use `@template="empty"` and put `EuiPageSection` and `EuiPageHeader` in the default block, in the order you want.

</EuiText>

<EuiSpacer />

<EuiCallOut @size="s" @title="Fixed headers">
  <p>If you have a fixed position header, the template automatically accounts for the padding offset based on the total number of page headers.</p>
</EuiCallOut>

```gjs component
import { EuiPageTemplate, EuiPageSection, EuiText, EuiPageHeader, EuiButton, EuiSkeletonText } from '@ember-eui/core/components';
import { array, hash } from '@ember/helper';

<template>
  <EuiPageTemplate @template="empty" @grow={{false}} @restrictWidth={{false}}>
    <:default>
      <EuiPageSection @grow={{false}} @color="subdued" @bottomBorder="extended">
        <EuiText @textAlign="center">
          <strong>
            Stack EuiPageSection and EuiPageHeader to create your custom content order.
          </strong>
        </EuiText>
      </EuiPageSection>
      <EuiPageHeader
        @iconType="logoElastic"
        @pageTitle="Page title"
        @description="Header description."
        @tabs={{array (hash label="Tab 1" isSelected=true) (hash label="Tab 2")}}
        @bottomBorder="extended"
      >
        <:rightSideItems as |Item|>
          <Item><EuiButton>Right side item</EuiButton></Item>
        </:rightSideItems>
      </EuiPageHeader>
      <EuiPageSection>
        <EuiSkeletonText @isLoading={{true}} @lines={{6}} />
      </EuiPageSection>
    </:default>
  </EuiPageTemplate>
</template>
```
