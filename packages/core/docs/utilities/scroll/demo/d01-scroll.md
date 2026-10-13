---
order: 1
---

# Vertical scroll

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiPanel, EuiText } from '@ember-eui/core/components';
import { euiScrollBarStyles, euiYScroll, euiYScrollWithShadows } from '@ember-eui/core/theming';

const bar = (theme) => [euiScrollBarStyles(theme), 'overflow: auto;'];
const scroll = (theme) => euiYScroll(theme, { height: '150px' });
const shadows = (theme) => [euiYScrollWithShadows(theme, { height: '150px' }), 'padding-block: 12px;'];
const items = [1, 2, 3, 4, 5, 6, 7, 8];

<template>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiText @size='s'><strong>euiScrollBarStyles</strong></EuiText>
      <EuiPanel @css={{bar}} tabindex='0' style='max-block-size: 150px'>
        {{#each items as |n|}}<EuiPanel @hasShadow={{false}}>Panel {{n}}</EuiPanel>{{/each}}
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiText @size='s'><strong>euiYScroll</strong></EuiText>
      <EuiPanel @css={{scroll}} tabindex='0'>
        {{#each items as |n|}}<EuiPanel @hasShadow={{false}}>Panel {{n}}</EuiPanel>{{/each}}
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiText @size='s'><strong>euiYScrollWithShadows</strong></EuiText>
      <EuiPanel @css={{shadows}} tabindex='0'>
        {{#each items as |n|}}<EuiPanel @hasShadow={{false}}>Panel {{n}}</EuiPanel>{{/each}}
      </EuiPanel>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
