---
order: 2
---

# Interpolation

<EuiText>

<strong>EuiI18n</strong> and the service's <EuiCode>lookupToken</EuiCode> support variable interpolation. In a translation like `Signed in as {name} ({email})`, two values can be interpolated (<EuiCode>name</EuiCode> and <EuiCode>email</EuiCode>). These values can be specified by passing a <EuiCode>@values</EuiCode> hash to <strong>EuiI18n</strong>, or by passing an object of values as the third argument to <EuiCode>lookupToken</EuiCode>. Interpolation values can be passed as a string, number, or a component.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { EuiButton, EuiI18n, EuiSpacer, EuiTitle } from '@ember-eui/core/components';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';

export default class I18nInterpolation extends Component {
  @service euiI18n;
  @tracked count = 0;

  get stringText() {
    return this.euiI18n.lookupToken(
      'euiI18nInterpolation.clickedCount',
      'Clicked on button {count} times.',
      { count: this.count }
    );
  }

  get functionText() {
    return this.euiI18n.lookupToken(
      'euiI18nInterpolation.clickedCount',
      ({ count }) => `Clicked on button ${count} time${count === 1 ? '' : 's'}.`,
      { count: this.count }
    );
  }

  @action
  increase() {
    this.count++;
  }

  <template>
    <EuiTitle @size='xs'>
      <h3>lookupToken with string interpolation</h3>
    </EuiTitle>
    <p>{{this.stringText}}</p>
    <EuiSpacer @size='l' />
    <EuiTitle @size='xs'>
      <h3>EuiI18n with string interpolation</h3>
    </EuiTitle>
    <p>
      <EuiI18n
        @token='euiI18nInterpolation.clickedCount'
        @default='Clicked on button {count} times.'
        @values={{hash count=this.count}}
        as |Token|
      >
        <Token />
      </EuiI18n>
    </p>
    <EuiSpacer @size='l' />
    <EuiTitle @size='xs'>
      <h3>lookupToken with function interpolation</h3>
    </EuiTitle>
    <p>{{this.functionText}}</p>
    <EuiSpacer @size='l' />
    <EuiButton @size='s' {{on 'click' this.increase}}>
      Increase count
    </EuiButton>
  </template>
}
```

