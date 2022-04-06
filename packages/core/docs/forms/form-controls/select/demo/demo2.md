---
order: 2
---

## Using blocks

<EuiText>
  <p>
    You can make use of the <strong>:prepend</strong> and <strong>:append</strong> blocks to customize the select.
  </p>
</EuiText>

```hbs template
<EuiSelect
  @value={{this.select1}}
  @hasNoInitialSelection={{true}}
  @options={{array
    (hash value='1' text='hello')
    (hash value='2' text='goodbye')
  }}
  {{on 'change' (pick 'target.value' (set this 'select1'))}}
>
  <:prepend as |classes|>
    <EuiFormLabel class={{classes}}>
      Prepend
    </EuiFormLabel>
  </:prepend>
  <:append as |classes|>
    <EuiFormLabel class={{classes}}>
      Append
    </EuiFormLabel>
  </:append>
</EuiSelect>
```

```javascript component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class extends Component {
  @tracked select1 = '';
}
```
