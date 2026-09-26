---
order: 1
---

# Two controls with a delimiter

<EuiText>

Render the controls in the `<:startControl>` and `<:endControl>` blocks,
with the yielded class. `@delimiter` changes the text between them (an
arrow by default); `<:prepend>` / `<:append>` add labels on the sides.

</EuiText>

```hbs template
<EuiFormControlLayoutDelimited @delimiter='+'>
  <:prepend as |classes|>
    <EuiFormLabel class={{classes}}>
      Add
    </EuiFormLabel>
  </:prepend>
  <:startControl as |classes|>
    <input
      type='number'
      placeholder='100'
      class='euiFieldNumber {{classes}}'
      aria-label='Use aria labels when no actual label is in use'
    />
  </:startControl>
  <:endControl as |classes|>
    <input
      type='number'
      placeholder='100'
      class='euiFieldNumber {{classes}}'
      aria-label='Use aria labels when no actual label is in use'
    />
  </:endControl>
</EuiFormControlLayoutDelimited>

<EuiSpacer />

<EuiFormControlLayoutDelimited @fullWidth={{true}}>
  <:prepend as |classes|>
    <EuiFormLabel class={{classes}}>
      Add
    </EuiFormLabel>
  </:prepend>
  <:startControl as |classes|>
    <input
      type='number'
      placeholder='100'
      class='euiFieldNumber {{classes}}'
      aria-label='Use aria labels when no actual label is in use'
    />
  </:startControl>
  <:endControl as |classes|>
    <input
      type='number'
      placeholder='100'
      class='euiFieldNumber {{classes}}'
      aria-label='Use aria labels when no actual label is in use'
    />
  </:endControl>
</EuiFormControlLayoutDelimited>

<EuiSpacer />

<EuiFormRow
  @fullWidth={{true}}
  @error={{array 'error1' 'error2'}}
  @isInvalid={{true}}
>
  <:label>
    Hello
  </:label>
  <:field>
    <EuiFormControlLayoutDelimited @fullWidth={{true}}>
      <:prepend as |classes|>
        <EuiFormLabel class={{classes}}>
          Prepend
        </EuiFormLabel>
      </:prepend>
      <:startControl as |classes|>
        <input
          type='number'
          placeholder='100'
          class='euiFieldNumber {{classes}}'
          aria-label='Use aria labels when no actual label is in use'
        />
      </:startControl>
      <:delimiter>
        \_(o.o)_/
      </:delimiter>
      <:endControl as |classes|>
        <input
          type='number'
          placeholder='100'
          class='euiFieldNumber {{classes}}'
          aria-label='Use aria labels when no actual label is in use'
        />
      </:endControl>
      <:append as |classes|>
        <EuiFormLabel class={{classes}}>
          Append
        </EuiFormLabel>
      </:append>
    </EuiFormControlLayoutDelimited>
  </:field>
  <:errors as |error|>
    <EuiIcon @type='faceSad' @color='danger' />
    {{error}}
  </:errors>
  <:helpText>
    Here is a hint
  </:helpText>
</EuiFormRow>

<EuiSpacer />
<EuiFormRow
  @error={{array 'error1' 'error2'}}
  @isInvalid={{true}}
  @label='Hello'
  @helpText="Here's a hint"
>
  <EuiFormControlLayoutDelimited @fullWidth={{true}}>
    <:startControl as |classes|>
      <input
        type='number'
        placeholder='100'
        class='euiFieldNumber {{classes}}'
        aria-label='Use aria labels when no actual label is in use'
      />
    </:startControl>
    <:endControl as |classes|>
      <input
        type='number'
        placeholder='100'
        class='euiFieldNumber {{classes}}'
        aria-label='Use aria labels when no actual label is in use'
      />
    </:endControl>
  </EuiFormControlLayoutDelimited>
</EuiFormRow>
```
