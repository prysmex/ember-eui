---
order: 7
---

# Nesting panels

<EuiText>
  <p>
Panels are one of the basic building blocks of EUI and have a wide variety of styles. They are a great tool to help segment and group content. But as layouts grow in complexity, <strong>nesting</strong> panels becomes necessary and it can sometimes be difficult to decide what style combinations make sense within a panel stack.</p><p>The following are some guidelines that are meant to help reduce the design choices necessary when nesting panels within panels.
  </p>
</EuiText>

```gjs component
import { EuiCard, EuiFlexGroup, EuiFlexItem, EuiPanel, EuiSpacer, EuiTitle } from '@ember-eui/core/components';

<template>
  <EuiSpacer @size='l' />
  <EuiPanel @color='subdued' @paddingSize='l' @hasShadow={{false}} style='justify-content: center; display: flex;'>
    <EuiPanel @hasShadow={{true}} @hasBorder={{false}} style='max-width: 650px;'>
      <EuiTitle @size='m'><span>Panel 1</span></EuiTitle>
      <EuiSpacer />
      <EuiPanel @color='subdued'>
        <EuiTitle @size='s'><span>Panel 2</span></EuiTitle>
        <EuiSpacer />
        <EuiFlexGroup @wrap={{true}}>
          <EuiFlexItem>
            <EuiCard @titleSize='xs' @layout='horizontal' @title='Card 1' @description='Cards are panels too.' />
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiCard @titleSize='xs' @layout='horizontal' @title='Card 2' @description='Cards are panels too.' />
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiCard @titleSize='xs' @layout='horizontal' @title='Card 3' @description='Cards are panels too.' />
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiPanel>
    </EuiPanel>
  </EuiPanel>
</template>
```
