---
order: 1
---

# Container query

<EuiText>

Drag the bottom right corner of the box to resize it. The text becomes small when the container is narrower than 300px.

</EuiText>

```gjs component
import { EuiSpacer, EuiText } from '@ember-eui/core/components';
import { euiContainerCSS, euiContainerQuery } from '@ember-eui/core/theming';

const container = euiContainerCSS('inline-size');
const small = ({ euiTheme }) => `
  ${euiContainerQuery('(width < 300px)')} {
    font-size: ${euiTheme.size.m};
    color: ${euiTheme.colors.danger};
  }
`;

<template>
  <EuiSpacer />
  <div style='resize: horizontal; overflow: auto; inline-size: 400px; max-inline-size: 100%; border: 1px solid #98a2b3; padding: 8px;'>
    <EuiText @css={{container}}>
      <EuiText @css={{small}}>
        <strong>This text will become small and red when the container is narrower than 300px.</strong>
      </EuiText>
    </EuiText>
  </div>
</template>
```
