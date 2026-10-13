---
order: 3
---

# CSS variables in plain CSS

<EuiText>

The `.theming-demo-note` rule below is ordinary CSS: it only reads
`--eui-*` variables. The nested dark and high contrast providers
re-declare them on their wrapper, so the same rule follows each section.

</EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';

<template>
  <style>
    .theming-demo-note {
      display: block;
      padding: var(--eui-size-m);
      border: var(--eui-border-thin);
      border-radius: var(--eui-border-radius-medium);
      background: var(--eui-color-background-base-subdued);
      color: var(--eui-color-text-subdued);
      font-family: var(--eui-font-family);
      font-size: var(--eui-font-size-s);
      line-height: var(--eui-line-height-s);
    }
    .theming-demo-note strong {
      color: var(--eui-color-text-heading);
      font-weight: var(--eui-font-weight-bold);
    }
  </style>
  <EuiFlexGroup @gutterSize="m" @wrap={{true}}>
    <EuiFlexItem>
      <span class="theming-demo-note"><strong>Page theme.</strong> Values from :root.</span>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiEmotionProvider @colorMode="dark">
        <span class="theming-demo-note"><strong>Dark section.</strong> Scoped on the wrapper.</span>
      </EuiEmotionProvider>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiEmotionProvider @highContrastMode={{true}}>
        <span class="theming-demo-note"><strong>High contrast.</strong> Stronger borders.</span>
      </EuiEmotionProvider>
    </EuiFlexItem>
  </EuiFlexGroup>
</template>
```
