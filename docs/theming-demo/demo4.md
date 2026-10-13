---
order: 4
---

# Brand overrides

<EuiText>

`@borealisOverrides` changes the tokens themselves, so EUI components,
style factories, `@css` theme functions and the CSS variables all follow.
Use mode-specific colors and override the semantic tokens you rely on.

</EuiText>

```gjs component
import {
  EuiBadge,
  EuiButton,
  EuiFlexGroup,
  EuiFlexItem,
  EuiLink,
  EuiPanel
} from '@ember-eui/core/components';
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';

const brand = {
  colors: {
    LIGHT: {
      primary: '#5a2ca0',
      textPrimary: '#4b2386',
      backgroundFilledPrimary: '#5a2ca0',
      backgroundLightPrimary: '#f1ebfb',
      borderBasePrimary: '#c9b5f5'
    },
    DARK: {
      primary: '#b79cf2',
      textPrimary: '#c9b5f5',
      backgroundFilledPrimary: '#b79cf2',
      backgroundLightPrimary: '#2a1a47',
      borderBasePrimary: '#6b4bb0'
    }
  },
  border: { radius: { medium: '2px', small: '2px' } }
};

const note = {
  color: 'var(--eui-color-text-primary)',
  borderColor: 'var(--eui-color-border-base-primary)'
};

<template>
  <EuiFlexGroup @gutterSize="l" @wrap={{true}}>
    <EuiFlexItem>
      <EuiPanel @hasBorder={{true}}>
        <EuiButton @fill={{true}}>Default</EuiButton>
        <EuiBadge @color="primary">Badge</EuiBadge>
        <EuiLink>Link</EuiLink>
      </EuiPanel>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiEmotionProvider @borealisOverrides={{brand}}>
        <EuiPanel @hasBorder={{true}} @css={{note}}>
          <EuiButton @fill={{true}}>Branded</EuiButton>
          <EuiBadge @color="primary">Badge</EuiBadge>
          <EuiLink>Link</EuiLink>
        </EuiPanel>
      </EuiEmotionProvider>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
