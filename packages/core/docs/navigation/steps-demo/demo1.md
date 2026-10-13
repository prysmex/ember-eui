---
order: 1
---

# Default

<EuiText>

**EuiSteps** presents procedural content in a numbered outline format. It is best used when presenting instructional content that must be conducted in a particular order. Each **EuiStep** requires a `@title` and its content in the block. Steps are numbered automatically by their order; use `@firstStepNumber` on **EuiSteps** to start from another number (a step's own `@step` still wins).

</EuiText>

<EuiSpacer />

```gjs component
import { EuiCode, EuiSpacer, EuiStep, EuiSteps, EuiText } from '@ember-eui/core/components';

<template>
<EuiSteps>
  <EuiStep @title="Step 1">
    <EuiText>
      <p>Do this first</p>
    </EuiText>
  </EuiStep>
  <EuiStep @title="Step 2">
    <EuiText>
      <p>Then this</p>
    </EuiText>
  </EuiStep>
</EuiSteps>
<EuiSpacer @size="m" />
<EuiText>
  <p>
    Set <EuiCode>@firstStepNumber</EuiCode> to continue step numbering after
    any type of break in the content
  </p>
</EuiText>
<EuiSpacer @size="m" />
<EuiSteps @firstStepNumber={{3}}>
  <EuiStep @title="Good step">
    <EuiText>
      <p>Do this first</p>
    </EuiText>
  </EuiStep>
  <EuiStep @title="Better step">
    <EuiText>
      <p>Then this</p>
    </EuiText>
  </EuiStep>
</EuiSteps>
</template>
```
