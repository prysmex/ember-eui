---
order: 1
---

# Component

<EuiText>
  <p>
    <strong>EuiAccordion</strong> has been purposely designed with minimal
    styles, allowing you to visually enhance it as needed (see the accordion
    form example). The only styling enforced by EUI is the caret icon, which
    indicates to users that the item can be opened.
  </p>
  <p>
    A <EuiCode>@buttonContent</EuiCode> argument (or the
    <EuiCode>&lt;:buttonContent&gt;</EuiCode> block) defines the content of the
    clickable area. On click it will expose the content block and animate based
    on the height of that content.
  </p>
  <p>
    For styling needs, classes can be individually applied with
    <EuiCode>class</EuiCode> (for the entire accordion), and
    <EuiCode>@buttonClassName</EuiCode> (for the clickable area).
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import { EuiAccordion, EuiPanel } from '@ember-eui/core/components';

<template>
<EuiAccordion @id="simpleAccordion">
  <:buttonContent>
    Click me to toggle
  </:buttonContent>
  <:content>
    <EuiPanel @color="subdued">
      Any content inside of <strong>EuiAccordion</strong> will appear here.
    </EuiPanel>
  </:content>
</EuiAccordion>
</template>
```
