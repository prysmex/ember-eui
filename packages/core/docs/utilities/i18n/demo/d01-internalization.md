---
order: 1
---

# Internalization

<EuiText>

<strong>EuiI18n</strong> allows localizing string and numeric values for internationalization. There are two provided ways to use this: the <strong>EuiI18n</strong> component, which yields a component rendering the text, and the <EuiCode>euiI18n</EuiCode> service, whose <EuiCode>lookupToken</EuiCode> method returns the string in JavaScript. In their simplest form, these take a <EuiCode>token</EuiCode> and a <EuiCode>default</EuiCode> value. <EuiCode>token</EuiCode> provides a reference to use when mapping to a localized value and <EuiCode>default</EuiCode> provides the untranslated value when no mapping is available.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { service } from '@ember/service';
import { EuiI18n, EuiSpacer, EuiTitle } from '@ember-eui/core/components';

export default class I18nBasic extends Component {
  @service euiI18n;

  get text() {
    return this.euiI18n.lookupToken(
      'euiI18nBasic.basicexample',
      'This is the English copy that would be replaced by a translation defined by the i18n.basicexample token.'
    );
  }

  <template>
    <EuiTitle @size='xs'>
      <h3>Basic euiI18n service usage</h3>
    </EuiTitle>
    <p>{{this.text}}</p>
    <EuiSpacer @size='l' />
    <EuiTitle @size='xs'>
      <h3>Basic EuiI18n usage</h3>
    </EuiTitle>
    <p>
      <EuiI18n
        @token='euiI18nBasic.basicexample'
        @default='This is the English copy that would be replaced by a translation defined by the i18n.basicexample token.'
        as |Token|
      >
        <Token />
      </EuiI18n>
    </p>
  </template>
}
```

