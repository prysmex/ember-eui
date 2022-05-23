---
order: 1
---

# Basic Card

<EuiText>
<p>At its core an <strong>EuiCard</strong> should contain a <EuiCode @language="text">title</EuiCode>,<EuiCode @language="text">description</EuiCode>, and an <EuiCode @language="text">icon</EuiCode>. You can make the whole card clickable by giving it an <EuiCode @language="text">onClick</EuiCode> handler or <EuiCode @language="text">href</EuiCode>.</p>
</EuiText>

```hbs template
<EuiFlexGroup @gutterSize='l'>
  {{#each this.icons as |icon|}}
    <EuiFlexItem>
      <EuiCard
        @onClick={{this.click}}
        @icon={{concat 'logo' icon}}
        @title={{concat 'Elastic ' icon}}
        @iconSize='xxl'
        @description="Example of a card's description. Stick to one or two sentences."
      />
    </EuiFlexItem>
  {{/each}}
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoCardComponent extends Component {
  @tracked icons = ['Beats', 'Cloud', 'Logging', 'Kibana'];

  @action
  click() {
    alert('clicked!');
  }
}
```
