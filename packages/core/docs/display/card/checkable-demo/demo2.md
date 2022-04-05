---
order: 2
---

<EuiCallOut @iconType='accessibility' @color='warning'>
<:title>
<span>When used as a radio group, you must provide a <EuiCode>fieldset</EuiCode> with a <EuiCode>legend</EuiCode> for accessibility.</span>
</:title>
</EuiCallOut>

```hbs template
<EuiFormFieldset @legend='With legend'>

  <EuiCheckableCard @label='Option One ' @checked={{false}} />
  <EuiSpacer size='m' />

  <EuiCheckableCard @label='Option Two ' @checked={{false}}>
    <:content>
      <EuiRadioGroup
        @options={{this.radios}}
        @idSelected={{this.selectedRadioId}}
        @onChange={{set this 'selectedRadioId'}}
      />
    </:content>
  </EuiCheckableCard>
  <EuiSpacer size='m' />
  <EuiCheckableCard
    @label='Option One '
    @checked={{false}}
    @disabled={{true}}
  />

</EuiFormFieldset>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoCheckableCardomponent extends Component {
  radios = [
    {
      id: 'radio-1',
      label: 'radio 1'
    },
    {
      id: 'radio-2',
      label: 'radio 2'
    },
    {
      id: 'radio-3',
      label: 'radio 3'
    },
    {
      id: 'radio-4',
      label: 'radio 4'
    }
  ];

  @tracked selectedRadioId = null;
}
```
