---
order: 6
---

# Context

<EuiText>

Upstream's <strong>EuiContext</strong> sets global internationalization copy for the EUI components inside it. In Ember EUI, add translations globally with the <EuiCode>euiI18n</EuiCode> service (see above), or pass a mapping to a single <strong>EuiI18n</strong> with <EuiCode>@i18n=&#123;&#123;hash mapping=...&#125;&#125;</EuiCode>, as in this example: the buttons switch the mapping used by the texts below.

</EuiText>

<EuiSpacer />

```hbs template
<EuiFlexGroup @gutterSize='s' @alignItems='center'>
  <EuiFlexItem @grow={{false}}>
    <EuiButton
      aria-pressed={{if (eq this.language 'en') 'true' 'false'}}
      @fill={{eq this.language 'en'}}
      {{on 'click' (fn this.setLanguage 'en')}}
    >
      <EuiI18n @token='euiContext.english' @default='English' @i18n={{this.i18n}} as |Token|><Token /></EuiI18n>
    </EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton
      aria-pressed={{if (eq this.language 'fr') 'true' 'false'}}
      @fill={{eq this.language 'fr'}}
      {{on 'click' (fn this.setLanguage 'fr')}}
    >
      <EuiI18n @token='euiContext.french' @default='French' @i18n={{this.i18n}} as |Token|><Token /></EuiI18n>
    </EuiButton>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size='m' />
<div lang={{this.language}}>
  <strong>
    <EuiI18n
      @token='euiContext.greeting'
      @default='Welcome, {name}!'
      @values={{hash name=this.displayName}}
      @i18n={{this.i18n}}
      as |Token|
    ><Token /></EuiI18n>
  </strong>
  <EuiSpacer @size='s' />
  <p>
    <EuiI18n @token='euiContext.guestNo' @default='You are guest #' @i18n={{this.i18n}} as |Token|><Token /></EuiI18n>
    <EuiI18nNumber @value={{1582394}} />
  </p>
  <EuiSpacer @size='m' />
  <EuiFormRow @label={{this.question}}>
    <EuiFieldText
      @value={{this.name}}
      @placeholder={{this.placeholder}}
      {{on 'input' this.updateName}}
    />
  </EuiFormRow>
  <EuiSpacer />
  <EuiButton>{{this.action}}</EuiButton>
</div>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';

const mappings = {
  en: {},
  fr: {
    'euiContext.english': 'Anglais',
    'euiContext.french': 'Française',
    'euiContext.greeting': 'Salutations, {name}!',
    'euiContext.guestNo': 'Vous êtes invité #',
    'euiContext.question': 'Quel est votre nom?',
    'euiContext.placeholder': 'Jean Dupont',
    'euiContext.action': 'Soumettre',
  },
};

export default class I18nContext extends Component {
  @service euiI18n;

  @tracked language = 'en';
  @tracked name = '';

  get i18n() {
    return { mapping: mappings[this.language] };
  }

  lookup(token, fallback) {
    return this.euiI18n._lookupToken({
      token,
      valueDefault: fallback,
      i18nMapping: this.i18n.mapping,
    });
  }

  get placeholder() {
    return this.lookup('euiContext.placeholder', 'John Doe');
  }

  get displayName() {
    return this.name === '' ? this.placeholder : this.name;
  }

  get question() {
    return this.lookup('euiContext.question', 'What is your name?');
  }

  get action() {
    return this.lookup('euiContext.action', 'Submit');
  }

  @action
  setLanguage(language) {
    this.language = language;
  }

  @action
  updateName(event) {
    this.name = event.target.value;
  }
}
```
