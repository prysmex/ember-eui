---
order: 1
---

```hbs template
<EuiRadioGroup
  @options={{this.radios}}
  @idSelected={{this.selectedRadioId}}
  @onChange={{set this 'selectedRadioId'}}
/>
<EuiSpacer />
<EuiRadioGroup
  @legend='With legend'
  @options={{this.radios}}
  @idSelected={{this.selectedRadioId}}
  @onChange={{set this 'selectedRadioId'}}
/>
<EuiSpacer />
Selected:
{{this.selectedRadioId}}
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
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
