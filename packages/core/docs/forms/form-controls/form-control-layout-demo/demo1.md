# Demo

```hbs template
<EuiFormControlLayout @icon="search">
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout @isLoading={{true}}>
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout @clear={{(optional)}}>
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer size="m" />
<EuiFormControlLayout @isLoading={{true}} @clear={{(optional)}}>
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout @isLoading={{true}} @icon="search">
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer size="m" />
<EuiFormControlLayout @isLoading={{true}} @icon="arrowDown" @iconSide="right">
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer size="m" />
<EuiFormControlLayout @clear={{(optional)}} @icon="search">
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer size="m" />
<EuiFormControlLayout @clear={{(optional)}} @icon="arrowDown" @iconSide="right">
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout @isLoading={{true}} @clear={{(optional)}} @icon="search">
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout @isLoading={{true}} @clear={{(optional)}} @icon="arrowDown" @iconSide="right">
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout @isLoading={{true}} @clear={{(optional)}} @icon="search">
  <input
    type="text"
    class="euiFieldText"
    aria-label="Use aria labels when no actual label is in use"
  />
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout>
  <:prepend as |classes|>
    <EuiFormLabel htmlFor="textField19" class={{classes}}>
      Label
    </EuiFormLabel>
  </:prepend>
  <:field>
    <input type="text" class="euiFieldText euiFieldText--inGroup" id="textField19" />
  </:field>
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout @readOnly={{true}}>
  <:prepend as |classes|>
    <EuiFormLabel htmlFor="textField19a" class={{classes}}>
      Read only
    </EuiFormLabel>
  </:prepend>
  <:field>
    <input type="text" class="euiFieldText euiFieldText--inGroup" id="textField19a" />
  </:field>
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout>
  <:prepend as |classes|>
    <EuiText @size="xs" class={{classes}}>
      <strong>
        %
      </strong>
    </EuiText>
  </:prepend>
  <:field>
    <input
      type="number"
      class="euiFieldNumber euiFieldNumber--inGroup"
      aria-label="Use aria labels when no actual label is in use"
    />
  </:field>
</EuiFormControlLayout>
<EuiSpacer @size="m" />
<EuiFormControlLayout @isLoading={{true}} @clear={{(optional)}}>
  <:prepend as |classes|>
    <EuiButtonEmpty @size="xs" @iconType="arrowDown" @iconSide="right" class={{classes}}>
      Button
    </EuiButtonEmpty>
  </:prepend>
  <:field>
    <input
      type="text"
      class="euiFieldText euiFieldText--inGroup"
      aria-label="Use aria labels when no actual label is in use"
    />
  </:field>
</EuiFormControlLayout>
```
