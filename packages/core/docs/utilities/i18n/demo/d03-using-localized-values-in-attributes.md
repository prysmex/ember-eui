---
order: 3
---

# Using localized values in attributes

<EuiText>

Some times a localized value is needed for an argument instead of rendering directly to the DOM. In these cases the service's <EuiCode>lookupToken</EuiCode> can be called from a getter, or <strong>EuiI18n</strong> can be used with a block that is called with the localized value.

</EuiText>

<EuiSpacer />

```hbs template
<EuiTitle @size='xs'>
  <h3>lookupToken used in an attribute</h3>
</EuiTitle>
<EuiSpacer />
<EuiFormRow @label="This text field's placeholder reads from euiI18nAttribute.placeholderName">
  <EuiFieldText @placeholder={{this.placeholder}} />
</EuiFormRow>
<EuiSpacer @size='xl' />
<EuiTitle @size='xs'>
  <h3>EuiI18n used with a block</h3>
</EuiTitle>
<EuiSpacer />
<EuiI18n
  @token='euiI18nAttribute.placeholderName'
  @default='John Doe'
  as |Token|
>
  <Token as |placeholderName|>
    <EuiFormRow @label="This text field's placeholder reads from euiI18nAttribute.placeholderName">
      <EuiFieldText @placeholder={{placeholderName}} />
    </EuiFormRow>
  </Token>
</EuiI18n>
```

```javascript component
import Component from '@glimmer/component';
import { service } from '@ember/service';

export default class I18nAttribute extends Component {
  @service euiI18n;

  get placeholder() {
    return this.euiI18n.lookupToken(
      'euiI18nAttribute.placeholderName',
      'John Doe'
    );
  }
}
```
