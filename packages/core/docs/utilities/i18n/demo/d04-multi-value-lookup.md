---
order: 4
---

# Multi-value lookup

<EuiText>

If many localized values are needed in a small area, pass several tokens at once: <strong>EuiI18n</strong> takes <EuiCode>@tokens</EuiCode> and a matching <EuiCode>@defaults</EuiCode> array (instead of <EuiCode>@token</EuiCode> and <EuiCode>@default</EuiCode>) and yields <em>one</em> array with the text of each token, like upstream's <EuiCode>tokens</EuiCode> and <EuiCode>defaults</EuiCode>. Read the texts by position with <EuiCode>get</EuiCode>. In JavaScript, call the service's <EuiCode>lookupToken</EuiCode> once per token.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { service } from '@ember/service';
import { array, get } from '@ember/helper';
import { EuiCard, EuiI18n, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';

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

  <template>
    <EuiTitle @size='xs'>
      <h3>EuiI18n with several tokens</h3>
    </EuiTitle>
    <div>
      <EuiText>
        <p>
          Both title and description for the card are looked up by one <strong>EuiI18n</strong>.
        </p>
      </EuiText>
      <EuiSpacer />
      <EuiI18n
        @tokens={{array 'euiI18nMulti.title' 'euiI18nMulti.description'}}
        @defaults={{array 'Card Title' 'Card Description'}}
        as |texts|
      >
        <EuiCard
          class='eui-displayInlineBlock'
          @title={{get texts 0}}
          @description={{get texts 1}}
        />
      </EuiI18n>
    </div>
    <EuiSpacer @size='l' />
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
  </template>
}
```
