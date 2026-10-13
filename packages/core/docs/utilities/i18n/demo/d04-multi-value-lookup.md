---
order: 4
---

# Multi-value lookup

<EuiText>

If many localized values are needed in a small area, call the service's <EuiCode>lookupToken</EuiCode> once per token from a getter. Ember EUI's <strong>EuiI18n</strong> looks up one <EuiCode>@token</EuiCode> at a time: the multiple <EuiCode>@tokens</EuiCode>/<EuiCode>@defaults</EuiCode> arguments of upstream's <strong>EuiI18n</strong> are not supported.

</EuiText>

<EuiSpacer />

```hbs template
<EuiTitle @size='xs'>
  <h3>lookupToken for several tokens</h3>
</EuiTitle>
<div>
  <EuiText>
    <p>
      Both title and description for the card are looked up in the component class.
    </p>
  </EuiText>
  <EuiSpacer />
  <EuiCard
    class='eui-displayInlineBlock'
    @title={{this.title}}
    @description={{this.description}}
  />
</div>
<EuiSpacer @size='l' />
<EuiTitle @size='xs'>
  <h3>One EuiI18n per token</h3>
</EuiTitle>
<div>
  <EuiText>
    <p>
      Each <strong>EuiI18n</strong> yields the text of its own token.
    </p>
  </EuiText>
  <EuiSpacer />
  <EuiI18n @token='euiI18nMulti.title' @default='Card Title' as |Title|>
    <EuiI18n @token='euiI18nMulti.description' @default='Card Description' as |Description|>
      <Title as |title|>
        <Description as |description|>
          <EuiCard
            class='eui-displayInlineBlock'
            @title={{title}}
            @description={{description}}
          />
        </Description>
      </Title>
    </EuiI18n>
  </EuiI18n>
</div>
```

```javascript component
import Component from '@glimmer/component';
import { service } from '@ember/service';

export default class I18nMulti extends Component {
  @service euiI18n;

  get title() {
    return this.euiI18n.lookupToken('euiI18nMulti.title', 'Card Title');
  }

  get description() {
    return this.euiI18n.lookupToken(
      'euiI18nMulti.description',
      'Card Description'
    );
  }
}
```
