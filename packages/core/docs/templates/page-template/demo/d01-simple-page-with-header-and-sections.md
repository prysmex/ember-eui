---
order: 1
---

# Simple page with header and sections

<EuiText>

All templates should start with a wrapping `EuiPageTemplate` to control some shared settings like `@paddingSize`, `@bottomBorder`, `@restrictWidth`, and `@panelled`. The template yields its parts (`as |T|`), which apply the appropriate args based on the full configuration:

- **`T.Sidebar`** extends `EuiPageSidebar` ([providing a sidebar](#providing-a-sidebar))
- **`T.Header`** extends [`EuiPageHeader`](/docs/core/docs/layout/page-header)
- **`T.Section`** extends [`EuiPageSection`](/docs/core/docs/layout/page-section)
- **`T.BottomBar`** extends [`EuiBottomBar`](/docs/core/docs/layout/bottom-bar)
- **`T.EmptyPrompt`** extends [`EuiEmptyPrompt`](/docs/core/docs/display/empty-prompt)

With the exception of `T.Sidebar` and `T.BottomBar`, the stacking order of the page contents is the order you render them in. You can also override the template's settings by passing args directly to a part.

</EuiText>

<EuiSpacer />

<EuiCallOut @size="s" @title="Fixed headers">
  <p>If you have fixed position headers, the template automatically accounts for the padding <code>@offset</code> based on the total height of the fixed headers (the <code>--euiFixedHeadersOffset</code> CSS variable). If you do not want the template to calculate this, pass <code>0</code> as the manual <code>@offset</code>.</p>
</EuiCallOut>

```gjs component
import { EuiPageTemplate, EuiText, EuiButton, EuiSkeletonText } from '@ember-eui/core/components';
import { array, hash } from '@ember/helper';

<template>
  <EuiPageTemplate
    @restrictWidth={{false}}
    @bottomBorder="extended"
    @offset={{0}}
    @grow={{false}}
    as |T|
  >
    <T.Section @grow={{false}} @color="subdued" @bottomBorder="extended">
      <EuiText @textAlign="center">
        <strong>
          Stack EuiPageTemplate sections and headers to create your custom content order.
        </strong>
      </EuiText>
    </T.Section>
    <T.Header
      @iconType="logoElastic"
      @pageTitle="Page title"
      @description="Header description."
      @tabs={{array (hash label="Tab 1" isSelected=true) (hash label="Tab 2")}}
    >
      <:rightSideItems as |Item|>
        <Item><EuiButton>Right side item</EuiButton></Item>
      </:rightSideItems>
    </T.Header>
    <T.Section>
      <EuiSkeletonText @isLoading={{true}} @lines={{6}} />
    </T.Section>
  </EuiPageTemplate>
</template>
```
