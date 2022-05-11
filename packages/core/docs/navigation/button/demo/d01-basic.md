---
order: 1
---

```hbs template

{{#each this.buttons as |type|}}
  {{#let
    (if (eq type 'disabled') undefined type)
    (eq type 'disabled')
  as |color isDisabled|}}
    <EuiFlexGroup
      @gutterSize='s'
      @alignItems="center"
      @wrap={{true}}
    >
      <EuiFlexItem @grow={{false}}>
        <EuiButton
          @color={{color}}
          @isDisabled={{isDisabled}}
        >
          {{type}}
        </EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton
          @color={{color}}
          @isDisabled={{isDisabled}}
          @fill={{true}}
        >
          Filled
        </EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton
          @color={{color}}
          @isDisabled={{isDisabled}}
          @size='s'
        >
          Small
        </EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton
          @color={{color}}
          @isDisabled={{isDisabled}}
          @fill={{true}}
          @size='s'
        >
          Small and filled
        </EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{true}}>
        <EuiButton
          @color={{color}}
          @isDisabled={{isDisabled}}
          @fullWidth={{true}}
        >
          Full width
        </EuiButton>
      </EuiFlexItem>
    </EuiFlexGroup>
  {{/let}}
{{/each}}
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoComponent extends Component {
  
  buttons = [
    'primary',
    'success',
    'warning',
    'danger',
    'text',
    'accent',
    'disabled',
  ];

}
```
