---
order: 1
---

# Demo

This component is different yet simplier from what you'd expect in ember in a way that you don't control the rendering of each checkbox, you just pass in an array of `@options` and `@idSelected` which you are in charge to calculate on subsequent `@onChange`'s, refer to the javascript snippet.

You can optionally pass `@valueKey` and `@labelKey` for a more flexible and ergonomic API, so you don't actually _have_ to map your options to
`{ id: '', label: '' }` which are the default `@valueKey` and `@labelKey`.

<EuiSpacer />


```hbs template
<EuiRadioGroup
  @options={{this.radios}}
  @idSelected={{this.selectedRadioId}}
  @onChange={{set this.selectedRadioId}}
/>
<EuiSpacer />
<EuiRadioGroup
  @legend="With legend"
  @options={{this.radios}}
  @idSelected={{this.selectedRadioId}}
  @onChange={{set this.selectedRadioId}}
/>
<EuiSpacer />
Selected:
{{this.selectedRadioId}}
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EuiTextFieldDemo1 extends Component {
  radios = [
    {
      id: 'radio-1',
      label: 'radio 1',
    },
    {
      id: 'radio-2',
      label: 'radio 2',
    },
    {
      id: 'radio-3',
      label: 'radio 3',
    },
    {
      id: 'radio-4',
      label: 'radio 4',
    },
  ];

  @tracked selectedRadioId = null;
}
```
