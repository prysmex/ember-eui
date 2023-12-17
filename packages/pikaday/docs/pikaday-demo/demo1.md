# Pikaday

<EuiText>
  <p>
  <EuiToolTip @content="We are using a fork for now">
    <:anchor>
    <EuiLink @target="_blank" @href="https://github.com/prysmex/ember-pikaday/tree/flexibility">ember-pikaday</EuiLink>
    </:anchor>
  </EuiToolTip> for <strong>@ember-eui/core</strong> integration
  </p>

  <p><EuiCodeBlock @language="bash" @isCopyable={{true}}>ember install @ember-eui/pikaday</EuiCodeBlock></p>

<EuiTitle @tagName="h3">Styles</EuiTitle>

<p>In order to give apps control over styling, the default CSS does not load unless you tell it to. The recommended way to load the CSS is just import the pikaday css anywhere in your app, literally it could be in application controller or something like that</p>

<EuiCodeBlock @language="js" @isCopyable={{true}}>
{{t "pikaday.styles_instructions"}}
</EuiCodeBlock>

</EuiText>

```hbs template
<EuiPikaday @onSelection={{this.setDate}} @value={{this.date}} />
<EuiText>
  <p>The selected date is:
    <EuiCode>{{this.date}}</EuiCode></p>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';
import 'ember-pikaday-prysmex/pikaday.css';

export default class extends Component {
  @tracked date = new Date();

  @action
  setDate(date) {
    this.date = date;
  }
}
```
