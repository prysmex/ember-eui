---
order: 8
---

# More complicated form labels

<EuiText>

Some controls are just hard though and will often require some custom work. Refer to an individual component's documentation and remember to test with a screen reader!

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiCode,
  EuiForm,
  EuiFormRow,
  EuiSelectable,
} from '@ember-eui/core/components';

export default class ComplicatedLabelsDemo extends Component {
  @tracked options = [
    { label: 'Black' },
    { label: 'Oolong' },
    { label: 'Green' },
    { label: 'White' },
    { label: 'Herbal' },
  ];

  @action
  setOptions(options) {
    this.options = options;
  }

  <template>
    <EuiForm>
      <EuiFormRow @label="Tea categories" @fullWidth={{true}}>
        <:helpText>
          The <strong>EuiFormRow</strong> label can&lsquo;t reach
          <strong>EuiSelectable</strong> without some help. Use
          <EuiCode>aria-label</EuiCode> or <EuiCode>aria-labelledby</EuiCode>
          to give a name to <strong>EuiSelectable</strong> that screen readers
          can use too.
        </:helpText>
        <:field>
          <EuiSelectable
            aria-label="Tea categories"
            @searchable={{true}}
            @options={{this.options}}
            @onChange={{this.setOptions}}
          />
        </:field>
      </EuiFormRow>
    </EuiForm>
  </template>
}
```
