---
order: 2
---

# Less content, more actions

<EuiText>

You can remove parts of the prompt to simplify it. You can also provide an array of multiple actions. Be sure to list primary actions first and secondary actions as empty buttons.

</EuiText>

```gjs component
import { EuiButton, EuiButtonEmpty, EuiEmptyPrompt } from '@ember-eui/core/components';
import { array } from '@ember/helper';

const ActionButton1 = <template><EuiButton @color="primary">Upgrade</EuiButton></template>;
const ActionButton2 = <template><EuiButtonEmpty @color="primary">Start a trial</EuiButtonEmpty></template>;

<template>
<EuiEmptyPrompt
  @title="Upgrade your license to use Machine Learning"
  @actions={{array
    ActionButton1
    ActionButton2
  }}
/>
</template>
```
