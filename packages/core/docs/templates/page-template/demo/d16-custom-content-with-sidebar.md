---
order: 16
---

# Custom content with a side bar

<EuiText>
  The empty template also works with a side bar. The content wrapper is
  transparent and has no border or shadow, leaving your panels to define the
  layout. As in every template, omit the pageHeader argument and header blocks
  when no header is needed.
</EuiText>

```gjs component
import { EuiPageTemplate, EuiLoadingContent, EuiFlexGrid, EuiFlexItem, EuiPanel, EuiText } from '@ember-eui/core/components';

<template>
  <EuiPageTemplate @template='empty' @restrictWidth={{800}}>
    <:pageSideBar><EuiLoadingContent @lines={{8}} /></:pageSideBar>
    <:default>
      <EuiFlexGrid @columns={{2}}>
        <EuiFlexItem><EuiPanel><EuiText><p>Project activity</p></EuiText></EuiPanel></EuiFlexItem>
        <EuiFlexItem><EuiPanel><EuiText><p>Recent updates</p></EuiText></EuiPanel></EuiFlexItem>
      </EuiFlexGrid>
    </:default>
  </EuiPageTemplate>
</template>
```
