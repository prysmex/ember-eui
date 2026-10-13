---
order: 2
---

# Full-width

<EuiText>

Form elements will automatically flex to a max-width of `400px`. You can optionally pass `@fullWidth` to the row and form control to expand to their container. This should be done rarely and usually you will only need it for isolated controls like search bars and sliders.

</EuiText>

```gjs component
import {
  EuiButton,
  EuiFieldSearch,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
  EuiRange,
  EuiSpacer,
  EuiTextArea,
} from '@ember-eui/core/components';

const noop = () => {};

<template>
  <EuiFlexGroup>
    <EuiFlexItem>
      <EuiFieldSearch
        placeholder="Search..."
        @fullWidth={{true}}
        @onSearch={{noop}}
        aria-label="An example of search with fullWidth"
      />
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiButton>Search</EuiButton>
    </EuiFlexItem>
  </EuiFlexGroup>

  <EuiSpacer @size="l" />

  <EuiFormRow
    @label="Works on form rows too"
    @fullWidth={{true}}
    @helpText="Note that the fullWidth argument is not passed to the form row's child"
  >
    <EuiRange @fullWidth={{true}} @min={{0}} @max={{100}} name="range" />
  </EuiFormRow>

  <EuiFormRow @label="Often useful for text areas" @fullWidth={{true}}>
    <EuiTextArea
      @fullWidth={{true}}
      placeholder="There is a reason we do not make forms ALWAYS 100% width. See how this text area becomes extremely hard to read when the individual lines get this long? It is much more readable when contained to a scannable max-width."
    />
  </EuiFormRow>
</template>
```
