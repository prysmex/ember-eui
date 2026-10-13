---
order: 5
---

# Colors, borders and widths (Ember EUI extra)

<EuiText>

`@color` sets the background, `@bottomBorder` adds a border under the
content (`'extended'` spans the padding too), and `@restrictWidth` centers
the content at EUI's default width or the width you pass.

</EuiText>

```gjs component
import { EuiPageSection, EuiTitle, EuiText } from '@ember-eui/core/components';

<template>
  <div style="border: 1px dashed #98A2B3">
    <EuiPageSection @color="subdued" @bottomBorder="extended" @paddingSize="m">
      <EuiTitle @size="s"><h2>Subdued, extended border</h2></EuiTitle>
    </EuiPageSection>
    <EuiPageSection @color="plain" @restrictWidth={{480}} @bottomBorder={{true}}>
      <EuiText>
        <p>Plain, content restricted to 480px and centered.</p>
      </EuiText>
    </EuiPageSection>
    <EuiPageSection @color="highlighted" @paddingSize="s">
      <EuiText @size="s"><p>Highlighted, small padding.</p></EuiText>
    </EuiPageSection>
  </div>
</template>
```
