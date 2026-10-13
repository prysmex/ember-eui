---
order: 5
---

# Legacy `@template` API (deprecated)

<EuiText>

Before upstream EUI made the template composable, `EuiPageTemplate` took a `@template` layout (`'default'`, `'centeredBody'`, `'centeredContent'` or `'empty'`), header options in `@pageHeader`, `@page…Props` for its inner components, and named blocks (`<:pageSideBar>`, `<:pageHeader…>`, `<:bottomBar>`, `<:default>` without block params). Upstream removed it; Ember EUI keeps it working until 16.0.0 but logs a deprecation (`ember-eui.eui-page-template-legacy.removed-upstream`).

The template uses the legacy API when the default block takes no block params, there is no `<:sidebar>` block and none of the composable-only args (`@panelled`, `@bottomBorder`, `@contentBorder`, `@offset`, `@responsive`, `@direction`, `@component`, `@mainProps`, `@css`) is given. See the [guidelines](/docs/core/docs/templates/page-template-guidelines#converting-from-legacy-layouts) for converting.

</EuiText>

```gjs component
import { EuiPageTemplate, EuiSkeletonText, EuiButton } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

<template>
  <EuiPageTemplate
    @grow={{false}}
    @restrictWidth={{false}}
    @pageHeader={{hash iconType="logoElastic" pageTitle="Page title"}}
  >
    <:pageSideBar>
      <EuiSkeletonText @isLoading={{true}} @lines={{8}} />
    </:pageSideBar>
    <:pageHeaderRightSideItems as |Item|>
      <Item><EuiButton>Right side item</EuiButton></Item>
    </:pageHeaderRightSideItems>
    <:default>
      <EuiSkeletonText @isLoading={{true}} @lines={{6}} />
    </:default>
  </EuiPageTemplate>
</template>
```
