---
order: 4
---

# Heading elements

<EuiText>

To aid with accessibility and hierarchical headings, you can and should pass in a heading element to use for each step title. The example below shows that the logical heading element should be an `h2` and therefore adds `@headingElement="h2"` to the **EuiSteps** (or to a single **EuiStep**, which wins).

The style of the title will **not** be affected.

</EuiText>

```gjs component
import { EuiSpacer, EuiStep, EuiSteps, EuiTitle } from '@ember-eui/core/components';

<template>
<EuiTitle @size="l" @tagName="h1">Heading 1</EuiTitle>

<EuiSpacer @size="xl" />

<EuiSteps @headingElement="h2">
  <EuiStep @title="Inspect me">
    <EuiTitle @size="xs" @tagName="h3">Did you notice the step title is inside a Heading 2 element?</EuiTitle>
  </EuiStep>
</EuiSteps>
</template>
```
