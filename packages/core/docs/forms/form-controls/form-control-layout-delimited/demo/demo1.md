---
order: 1
---

# Delimited layout

<EuiText>

Like `EuiFormControlLayout`, `EuiFormControlLayoutDelimited` is generally used internally to consistently style form controls. This component specifically lays out two form controls with center text or an icon.

It takes all of the same arguments as `EuiFormControlLayout`. Instead of a default block it uses a **single** `<:startControl>` and a **single** `<:endControl>` block, each yielding the class to put on the control. You can optionally change the center content with the `<:delimiter>` block (like an `EuiIcon`) or the `@delimiter` string.

</EuiText>

```gjs component
import {
  EuiFieldNumber,
  EuiFormAppend,
  EuiFormControlLayoutDelimited,
  EuiFormPrepend,
  EuiIcon,
} from '@ember-eui/core/components';

const noop = () => {};

<template>
  <div style="display: flex; flex-wrap: wrap; gap: 24px">
    <EuiFormControlLayoutDelimited @fullWidth={{true}}>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
      <:append><EuiFormAppend @label="px" /></:append>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited @icon="vectorSquare">
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited @clear={{noop}} @isLoading={{true}}>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited @isLoading={{true}}>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited @compressed={{true}}>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited>
      <:prepend><EuiFormPrepend @label="Add" /></:prepend>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:delimiter>+</:delimiter>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited>
      <:prepend><EuiFormPrepend @label="Merge" /></:prepend>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:delimiter><EuiIcon @type="merge" /></:delimiter>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited @readOnly={{true}}>
      <:prepend><EuiFormPrepend @label="Read Only" /></:prepend>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" @readOnly={{true}} aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" @readOnly={{true}} aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited @isDisabled={{true}}>
      <:prepend><EuiFormPrepend @label="Disabled" /></:prepend>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" @disabled={{true}} aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" @disabled={{true}} aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
    <EuiFormControlLayoutDelimited @isInvalid={{true}}>
      <:prepend><EuiFormPrepend @label="Invalid" /></:prepend>
      <:startControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="0" @isInvalid={{true}} aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:startControl>
      <:endControl as |classes|>
        <EuiFieldNumber @controlOnly={{true}} placeholder="100" @isInvalid={{true}} aria-label="Use aria labels when no actual label is in use" class={{classes}} />
      </:endControl>
    </EuiFormControlLayoutDelimited>
  </div>
</template>
```
