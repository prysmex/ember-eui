---
order: 1
---

# Form control layout

<EuiText>

`EuiFormControlLayout` is generally used internally to consistently style form controls, but it's published in case you want to create your own form control which matches those of EUI. This is a **building block only**. The examples below demonstrate its various states and utilize the `@controlOnly` and `@type` arguments of `EuiFieldText` as the wrapped control.

</EuiText>

```gjs component
import {
  EuiFieldNumber,
  EuiFieldText,
  EuiFormAppend,
  EuiFormControlLayout,
  EuiFormPrepend,
} from '@ember-eui/core/components';

const noop = () => {};

<template>
  <div style="display: inline-flex; flex-wrap: wrap; gap: 24px">
    <EuiFormControlLayout @icon="magnify">
      <EuiFieldText @controlOnly={{true}} @type="search" aria-label="Use aria labels when no actual label is in use" />
    </EuiFormControlLayout>
    <EuiFormControlLayout @isLoading={{true}}>
      <EuiFieldText @controlOnly={{true}} aria-label="Use aria labels when no actual label is in use" />
    </EuiFormControlLayout>
    <EuiFormControlLayout @clear={{noop}}>
      <EuiFieldText @controlOnly={{true}} aria-label="Use aria labels when no actual label is in use" />
    </EuiFormControlLayout>
    <EuiFormControlLayout @isInvalid={{true}}>
      <EuiFieldText @controlOnly={{true}} @isInvalid={{true}} aria-label="Use aria labels when no actual label is in use" />
    </EuiFormControlLayout>
    <EuiFormControlLayout @clear={{noop}} @icon="magnify">
      <EuiFieldText @controlOnly={{true}} @type="search" aria-label="Use aria labels when no actual label is in use" />
    </EuiFormControlLayout>
    <EuiFormControlLayout @isLoading={{true}} @isDropdown={{true}}>
      <EuiFieldText @controlOnly={{true}} aria-label="Use aria labels when no actual label is in use" />
    </EuiFormControlLayout>
    <EuiFormControlLayout @clear={{noop}} @isDropdown={{true}} @icon="stopFill" @iconColor="success">
      <EuiFieldText @controlOnly={{true}} aria-label="Use aria labels when no actual label is in use" />
    </EuiFormControlLayout>
    <EuiFormControlLayout @isLoading={{true}} @clear={{noop}} @icon="bolt" @iconSide="right" @isDropdown={{true}}>
      <EuiFieldText @controlOnly={{true}} aria-label="Use aria labels when no actual label is in use" />
    </EuiFormControlLayout>
    <EuiFormControlLayout>
      <:prepend><EuiFormPrepend @inputId="labelInput" @label="Label" /></:prepend>
      <:field><EuiFieldText @controlOnly={{true}} @id="labelInput" aria-label="Use aria labels when no actual label is in use" /></:field>
    </EuiFormControlLayout>
    <EuiFormControlLayout @readOnly={{true}}>
      <:prepend><EuiFormPrepend @inputId="readOnlyInput" @label="Read only" /></:prepend>
      <:field><EuiFieldText @controlOnly={{true}} @id="readOnlyInput" @readOnly={{true}} aria-label="Use aria labels when no actual label is in use" /></:field>
      <:append><EuiFormAppend @element="button" @label="Button" /></:append>
    </EuiFormControlLayout>
    <EuiFormControlLayout>
      <:field><EuiFieldNumber @controlOnly={{true}} aria-label="Use aria labels when no actual label is in use" /></:field>
      <:append><EuiFormAppend @label="%" /></:append>
    </EuiFormControlLayout>
    <EuiFormControlLayout @isLoading={{true}} @clear={{noop}}>
      <:prepend><EuiFormPrepend @element="button" @iconRight="chevronSingleDown" @label="Button" /></:prepend>
      <:field><EuiFieldText @controlOnly={{true}} aria-label="Use aria labels when no actual label is in use" /></:field>
    </EuiFormControlLayout>
  </div>
</template>
```
