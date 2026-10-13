---
order: 2
---

# Horizontal scroll

```gjs component
import { EuiPanel, EuiText } from '@ember-eui/core/components';
import { euiXScroll, euiXScrollWithShadows } from '@ember-eui/core/theming';

const scroll = (theme) => euiXScroll(theme);
const shadows = (theme) => [euiXScrollWithShadows(theme), 'padding-inline: 12px;'];
<template>
  <EuiText @size='s'><strong>euiXScroll</strong></EuiText>
  <EuiPanel @css={{scroll}} tabindex='0'>
    <div style='inline-size: 900px; padding-block: 8px;'>This content is wider than its container, so it scrolls horizontally with the minimal scroll bar.</div>
  </EuiPanel>
  <EuiText @size='s'><strong>euiXScrollWithShadows</strong></EuiText>
  <EuiPanel @css={{shadows}} tabindex='0'>
    <div style='inline-size: 900px; padding-block: 8px;'>This content is wider than its container, and its scrolled edges are masked.</div>
  </EuiPanel>
</template>
```
