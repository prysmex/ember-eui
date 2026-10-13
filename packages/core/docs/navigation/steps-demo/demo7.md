---
order: 7
---

# Steps as data

<EuiText>

Like upstream's `steps` prop, **EuiSteps** also takes the steps as an array with `@steps`: each entry has the `title`, `status`, `titleSize` and `headingElement` of an **EuiStep**, and its content as `children` text. For rich content, the `<:step>` block is yielded each entry and its index. Steps are numbered from `@firstStepNumber`. The array is never changed.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiCode, EuiCodeBlock, EuiSpacer, EuiSteps, EuiText } from '@ember-eui/core/components';

const firstSetOfSteps = [
  { title: 'Step 1', children: 'Do this first' },
  { title: 'Step 2', children: 'Then this' }
];

const nextSetOfSteps = [
  { title: 'Good step', command: 'npm install' },
  { title: 'Better step', command: 'npm start', status: 'complete' }
];

<template>
  <EuiSteps @steps={{firstSetOfSteps}} />

  <EuiSpacer @size="m" />
  <EuiText>
    <p>
      Set <EuiCode>@firstStepNumber</EuiCode> to continue step numbering after
      any type of break in the content
    </p>
  </EuiText>
  <EuiSpacer @size="m" />

  <EuiSteps @firstStepNumber={{3}} @steps={{nextSetOfSteps}}>
    <:step as |step|>
      <EuiText><p>Run this code snippet:</p></EuiText>
      <EuiSpacer @size="s" />
      <EuiCodeBlock @language="bash">{{step.command}}</EuiCodeBlock>
    </:step>
  </EuiSteps>
</template>
```
