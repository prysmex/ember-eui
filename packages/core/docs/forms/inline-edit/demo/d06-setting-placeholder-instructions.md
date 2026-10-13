---
order: 6
---

# Setting placeholder instructions

<EuiText>

The `@placeholder` argument will display in both read and edit mode whenever the inline edit's value is empty. Use placeholder text to provide guidance or instructions to consumers as to what they're editing.

</EuiText>

```gjs component
import { EuiInlineEditText, EuiSpacer, EuiInlineEditTitle } from '@ember-eui/core/components';

<template>
  <EuiInlineEditText
    @inputAriaLabel="Placeholder text example"
    @defaultValue=""
    @placeholder="Add a description"
  />
  <EuiSpacer />
  <EuiInlineEditTitle
    @heading="h3"
    @inputAriaLabel="Placeholder title example"
    @defaultValue=""
    @placeholder="Set your username"
  />
</template>
```
