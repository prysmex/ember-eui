---
order: 1
---

# Default

<EuiText>

**EuiSteps** presents procedural content in a numbered outline format. It is best used when presenting instructional content that must be conducted in a particular order. Each **EuiStep** requires a `@title` and its content in the block. Ember EUI has no `firstStepNumber`: pass each step its own `@step` number.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiCode, EuiSpacer, EuiStep, EuiSteps, EuiText } from '@ember-eui/core/components';

<template>
<EuiSteps>
  <EuiStep @step={{1}} @title="Step 1">
    <EuiText>
      <p>Do this first</p>
    </EuiText>
  </EuiStep>
  <EuiStep @step={{2}} @title="Step 2">
    <EuiText>
      <p>Then this</p>
    </EuiText>
  </EuiStep>
</EuiSteps>
<EuiSpacer @size="m" />
<EuiText>
  <p>
    Set <EuiCode>@step</EuiCode> to continue step numbering after any type of
    break in the content
  </p>
</EuiText>
<EuiSpacer @size="m" />
<EuiSteps>
  <EuiStep @step={{3}} @title="Good step">
    <EuiText>
      <p>Do this first</p>
    </EuiText>
  </EuiStep>
  <EuiStep @step={{4}} @title="Better step">
    <EuiText>
      <p>Then this</p>
    </EuiText>
  </EuiStep>
</EuiSteps>
</template>
```
