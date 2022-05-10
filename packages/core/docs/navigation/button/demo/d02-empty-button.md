---
order: 2
---

# Empty button

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
        <EuiButtonEmpty
          @color={{color}}
          @isDisabled={{isDisabled}}
        >
          {{type}}
        </EuiButtonEmpty>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButtonEmpty
          @color={{color}}
          @isDisabled={{isDisabled}}
          @size='s'
        >
          Small
        </EuiButtonEmpty>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButtonEmpty
          @color={{color}}
          @isDisabled={{isDisabled}}
          @size='xs'
        >
          Extra small
        </EuiButtonEmpty>
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