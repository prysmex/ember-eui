---
order: 2
---

# Collapsible nav group

<EuiText>
	<p>
		An <strong>EuiCollapsibleNavGroup</strong> adds some basic borders and <EuiCode>@background</EuiCode> color of <EuiCode>none</EuiCode>, <EuiCode>light</EuiCode>, or <EuiCode>dark</EuiCode>. Give each section a heading by providing an optional <EuiCode>&lt;:title&gt;</EuiCode> block and <EuiCode>@iconType</EuiCode>. Make the section collapsible (accordion style) with <EuiCode>@isCollapsible=&#123;&#123;true&#125;&#125;</EuiCode>.
	</p>
	<p>
    	When in <EuiCode>@isCollapsible</EuiCode> mode, a <EuiCode>&lt;:title&gt;</EuiCode> block and <EuiCode>@initialIsOpen</EuiCode> are required.
	</p>
</EuiText>

<EuiSpacer />

```gjs component
import { EuiCode, EuiCollapsibleNavGroup, EuiText } from '@ember-eui/core/components';

<template>
<EuiCollapsibleNavGroup>
  <:content>
    <EuiText @size="s" @color="subdued">
      <p>This is a basic group without any modifications</p>
    </EuiText>
  </:content>
</EuiCollapsibleNavGroup>
<EuiCollapsibleNavGroup @iconType="logoElastic">
  <:title>Nav group</:title>
  <:content>
    <EuiText @size="s" @color="subdued">
      <p>
        This is a nice group with a heading supplied via the
        <EuiCode>&lt;:title&gt;</EuiCode> block and
        <EuiCode>@iconType</EuiCode>.
      </p>
    </EuiText>
  </:content>
</EuiCollapsibleNavGroup>
<EuiCollapsibleNavGroup
  @background="light"
  @isCollapsible={{true}}
  @iconType="logoElastic"
  @initialIsOpen={{true}}
>
  <:title>Nav group</:title>
  <:content>
    <EuiText @size="s" @color="subdued">
      <p>
        This group is <EuiCode>collapsible</EuiCode> and set with
        <EuiCode>@initialIsOpen</EuiCode>. It has a heading that is the
        collapsing button via the <EuiCode>&lt;:title&gt;</EuiCode> block and
        <EuiCode>@iconType</EuiCode>.
      </p>
    </EuiText>
  </:content>
</EuiCollapsibleNavGroup>
<EuiCollapsibleNavGroup
  @iconType="logoGCPMono"
  @iconSize="xxl"
  @titleSize="s"
  @isCollapsible={{true}}
  @initialIsOpen={{false}}
  @background="dark"
>
  <:title>Nav group</:title>
  <:content>
    <EuiText @size="s">
      <p>
        This is a <EuiCode>dark</EuiCode> <EuiCode>collapsible</EuiCode> group
        that is initially set to closed,
        <EuiCode>@iconSize="xxl"</EuiCode> and
        <EuiCode>@titleSize="s"</EuiCode>.
      </p>
    </EuiText>
  </:content>
</EuiCollapsibleNavGroup>
</template>
```
