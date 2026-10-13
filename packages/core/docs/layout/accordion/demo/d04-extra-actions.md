---
order: 4
---

# Extra actions

<EuiText>
  Use the <EuiCode>@extraAction</EuiCode> argument to pass an extra action displayed on the right of any accordion. Usually this is a delete or button, but can be anything. Note that this action is separate from the click state that expands the accordion. This is needed to make it accessible.
</EuiText>

```gjs component
import { EuiAccordion, EuiButton } from '@ember-eui/core/components';

<template>
<EuiAccordion @paddingSize='l' @extraAction={{true}}>
  <:buttonContent>
    Click to open
  </:buttonContent>
  <:content>
    <strong>Opened content.</strong>
  </:content>
  <:extraAction>
    <EuiButton @size='s'>Extra action!</EuiButton>
  </:extraAction>
</EuiAccordion>
</template>
```
