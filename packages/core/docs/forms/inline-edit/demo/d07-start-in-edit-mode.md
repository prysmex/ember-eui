---
order: 7
---

# Start in edit mode

<EuiText>

Use the `@startWithEditOpen` argument to default to opening in edit mode.

</EuiText>

```gjs component
import { EuiInlineEditText, EuiSpacer, EuiInlineEditTitle } from '@ember-eui/core/components';

<template>
  <EuiInlineEditText
    @inputAriaLabel="Edit text inline"
    @defaultValue="This text starts in edit mode"
    @startWithEditOpen={{true}}
  />
  <EuiSpacer />
  <EuiInlineEditTitle
    @heading="h3"
    @inputAriaLabel="Edit title inline"
    @defaultValue="This title starts in edit mode"
    @startWithEditOpen={{true}}
  />
</template>
```
