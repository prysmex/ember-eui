---
order: 8
---

# Checkable cards in a fieldset

<EuiText>

When checkable cards act as a radio group, wrap them in an
`EuiFormFieldset` with a `@legend`, and give them the same `name`, so
screen readers announce the question with each option. A card's
`<:content>` block can hold more controls, shown under its label.

</EuiText>

```hbs template
<EuiFormFieldset @legend='With legend'>

  <EuiCheckableCard @label='Option One ' @checked={{false}} />
  <EuiSpacer @size='m' />

  <EuiCheckableCard @label='Option Two ' @checked={{false}}>
    <:content>
      <EuiRadioGroup
        @options={{this.radios}}
        @idSelected={{this.selectedRadioId}}
        @onChange={{set this 'selectedRadioId'}}
      />
    </:content>
  </EuiCheckableCard>
  <EuiSpacer @size='m' />
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
