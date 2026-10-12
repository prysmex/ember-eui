---
order: 1
---

# Icons, loading and clear button

<EuiText>

Wrap a control in `EuiFormControlLayout` to get EUI's icon, spinner and
clear button. Here the controls are EUI fields with `@controlOnly={{true}}`:
they render just their styled `<input>`, which makes room for the icons.

</EuiText>

```hbs template
<EuiFormControlLayout @icon='search'>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @isLoading={{true}}>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @clear={{(optional)}}>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @isLoading={{true}} @clear={{(optional)}}>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @isLoading={{true}} @icon='search'>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @isLoading={{true}} @icon='arrowDown' @iconSide='right'>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @clear={{(optional)}} @icon='search'>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @clear={{(optional)}} @icon='arrowDown' @iconSide='right'>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @isLoading={{true}} @clear={{(optional)}} @icon='search'>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout
  @isLoading={{true}}
  @clear={{(optional)}}
  @icon='arrowDown'
  @iconSide='right'
>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @isLoading={{true}} @clear={{(optional)}} @icon='search'>
  <EuiFieldText
    @controlOnly={{true}}
    aria-label='Use aria labels when no actual label is in use'
  />
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout>
  <:prepend as |classes|>
    <EuiFormLabel for='textField19' class={{classes}}>
      Label
    </EuiFormLabel>
  </:prepend>
  <:field>
    <EuiFieldText
      @controlOnly={{true}}
      @id='textField19'
    />
  </:field>
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @readOnly={{true}}>
  <:prepend as |classes|>
    <EuiFormLabel for='textField19a' class={{classes}}>
      Read only
    </EuiFormLabel>
  </:prepend>
  <:field>
    <EuiFieldText
      @controlOnly={{true}}
      @id='textField19a'
    />
  </:field>
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout>
  <:prepend as |classes|>
    <EuiText @size='xs' class={{classes}}>
      <strong>
        %
      </strong>
    </EuiText>
  </:prepend>
  <:field>
    <EuiFieldNumber
      @controlOnly={{true}}
      aria-label='Use aria labels when no actual label is in use'
    />
  </:field>
</EuiFormControlLayout>
<EuiSpacer @size='m' />
<EuiFormControlLayout @isLoading={{true}} @clear={{(optional)}}>
  <:prepend as |classes|>
    <EuiButtonEmpty
      @size='xs'
      @iconType='arrowDown'
      @iconSide='right'
      class={{classes}}
    >
      Button
    </EuiButtonEmpty>
  </:prepend>
  <:field>
    <EuiFieldText
      @controlOnly={{true}}
      aria-label='Use aria labels when no actual label is in use'
    />
  </:field>
</EuiFormControlLayout>
```
