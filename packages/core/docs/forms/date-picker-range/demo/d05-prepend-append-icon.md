---
order: 5
---

# Prepend, append and icon side

<EuiText>

The <EuiCode>&lt;:prepend&gt;</EuiCode> and <EuiCode>&lt;:append&gt;</EuiCode> blocks (upstream <EuiCode>prepend</EuiCode> / <EuiCode>append</EuiCode>) add content around the inputs; they yield the class to put on it. <EuiCode>@iconSide="right"</EuiCode> moves an <EuiCode>@iconType</EuiCode> to the right. With <EuiCode>@isCustom</EuiCode>, the start and end blocks yield only the delimited input class, for controls styled on their own. Inline ranges ignore the prepend and append.

</EuiText>

```gjs component
import { EuiDatePickerRange, EuiFieldText, EuiFormPrepend, EuiFormAppend } from '@ember-eui/core/components';

<template>
  <EuiDatePickerRange @iconType="clock" @iconSide="right">
    <:prepend>
      <EuiFormPrepend @label="Window" />
    </:prepend>
    <:start as |className|>
      <EuiFieldText @controlOnly={{true}} type="date" class={{className}} aria-label="Start date" />
    </:start>
    <:end as |className|>
      <EuiFieldText @controlOnly={{true}} type="date" class={{className}} aria-label="End date" />
    </:end>
    <:append>
      <EuiFormAppend @label="UTC" />
    </:append>
  </EuiDatePickerRange>
</template>
```
