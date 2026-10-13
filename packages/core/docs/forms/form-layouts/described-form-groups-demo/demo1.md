---
order: 1
---

# Described form groups

<EuiText>

Use the `EuiDescribedFormGroup` component to create sections of associated form controls and rows. It can also simply be used with one `EuiFormRow` as a way to display additional text next to the field (on mobile, it will revert to being stacked).

The `<:title>` is rendered as a heading (set its level with `@titleTagName`), the `<:description>` is wrapped in a small, subdued text block, and the form rows go in the default block.

</EuiText>

```gjs component
import {
  EuiDescribedFormGroup,
  EuiFieldText,
  EuiFilePicker,
  EuiForm,
  EuiFormRow,
  EuiLink,
  EuiRange,
  EuiSelect,
} from '@ember-eui/core/components';

const options = [
  { value: 'option_one', text: 'Option one' },
  { value: 'option_two', text: 'Option two' },
  { value: 'option_three', text: 'Option three' },
];

<template>
  <EuiForm @tagName="form">
    <EuiDescribedFormGroup @titleTagName="h3">
      <:title>Single text field</:title>
      <:description>
        <p>
          Descriptions are wrapped in a small, subdued
          <EuiLink @href="/docs/display/text"><strong>EuiTextBlock</strong></EuiLink>.
          It can have links or any other type of content. Be sure to wrap
          nodes in a paragraph tag.
        </p>
      </:description>
      <:default>
        <EuiFormRow @label="Text field">
          <EuiFieldText name="first" aria-label="Example" />
        </EuiFormRow>
      </:default>
    </EuiDescribedFormGroup>

    <EuiDescribedFormGroup @titleTagName="h3">
      <:title>No description</:title>
      <:default>
        <EuiFormRow @label="Text field">
          <EuiFieldText name="first" />
        </EuiFormRow>
      </:default>
    </EuiDescribedFormGroup>

    <EuiDescribedFormGroup @titleTagName="h3">
      <:title>Multiple fields</:title>
      <:description>
        Here are three form rows. The first form row does not have a label.
      </:description>
      <:default>
        <EuiFormRow @hasEmptyLabelSpace={{true}} @helpText="This is a help text">
          <EuiSelect
            @hasNoInitialSelection={{true}}
            @options={{options}}
            aria-label="An example of a form element without a visible label"
          />
        </EuiFormRow>
        <EuiFormRow @label="File picker">
          <EuiFilePicker />
        </EuiFormRow>
        <EuiFormRow @label="Range">
          <EuiRange @min={{0}} @value={{50}} @max={{100}} name="range" />
        </EuiFormRow>
      </:default>
    </EuiDescribedFormGroup>
  </EuiForm>
</template>
```
