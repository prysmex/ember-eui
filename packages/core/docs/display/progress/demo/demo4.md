---
order: 4
---

# Colors

<EuiText>
<p><strong>EuiProgress</strong> supports a few options for <EuiCode @language="text">color</EuiCode>. You can pass any value from our basic color set or from our visualization palette (<EuiCode @language="text">vis0</EuiCode> through <EuiCode @language="text">vis9</EuiCode>). To learn more about color usage, go to the <a href="#/guidelines/colors">Color guidelines</a> page.</p>
</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    {{#each this.mainColors as |color|}}
      <EuiProgress
        @valueText={{true}}
        @value={{80}}
        @max={{100}}
        @color={{color}}
        @size='m'
      >
        <:label>
          {{color}}
        </:label>
      </EuiProgress>
      <EuiSpacer size='s' />
    {{/each}}
  </EuiFlexItem>
  <EuiFlexItem>
    {{#each this.visColors as |color|}}
      <EuiProgress
        @valueText={{true}}
        @value={{80}}
        @max={{100}}
        @color={{color}}
        @size='m'
      >
        <:label>
          {{color}}
        </:label>
      </EuiProgress>
      <EuiSpacer size='s' />
    {{/each}}
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { typeToPathMap } from '@ember-eui/core/utils/css-mappings/eui-icon';

export default class DemoIconComponent extends Component {
  @tracked mainColors = [
    'primary',
    'success',
    'warning',
    'danger',
    'subdued',
    'accent'
  ];

  @tracked visColors = [
    'vis0',
    'vis1',
    'vis2',
    'vis3',
    'vis4',
    'vis5',
    'vis6',
    'vis7',
    'vis8',
    'vis9'
  ];
}
```
