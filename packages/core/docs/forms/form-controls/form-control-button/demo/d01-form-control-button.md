---
order: 1
---

# Form control button

<EuiText>

It stretches to its container by default; pass `@fullWidth={{false}}` for
the form width. `@iconType` and `@iconSide` add an icon, `@isLoading` a
spinner, and the block extra content after the text.

</EuiText>

```gjs component
import { EuiFormRow, EuiFormControlButton, EuiNotificationBadge } from '@ember-eui/core/components';

<template>
  <EuiFormRow @label="Owner">
    <EuiFormControlButton @value="Jane Cooper" @iconType="user" />
  </EuiFormRow>
  <EuiFormRow @label="Category">
    <EuiFormControlButton
      @placeholder="Select a category"
      @iconType="arrowDown"
      @iconSide="right"
      @fullWidth={{false}}
    />
  </EuiFormRow>
  <EuiFormRow @label="Tags">
    <EuiFormControlButton @value="Production">
      <EuiNotificationBadge @color="subdued">3</EuiNotificationBadge>
    </EuiFormControlButton>
  </EuiFormRow>
  <EuiFormRow @label="Compressed and invalid" @isInvalid={{true}}>
    <EuiFormControlButton
      @value="Invalid value"
      @compressed={{true}}
      @isInvalid={{true}}
    />
  </EuiFormRow>
  <EuiFormRow @label="Loading">
    <EuiFormControlButton @value="Loading" @isLoading={{true}} />
  </EuiFormRow>
</template>
```
