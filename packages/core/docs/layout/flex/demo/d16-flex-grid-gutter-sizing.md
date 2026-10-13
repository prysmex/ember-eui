---
order: 16
---

# Gutter sizing

<EuiText>

The `@gutterSize` arg can be applied to a parent `EuiFlexGrid` to adjust the spacing between child `EuiFlexItem`s.

</EuiText>

```gjs component
import { EuiFlexGrid, EuiFlexItem, EuiSpacer } from '@ember-eui/core/components';
import Component from '@glimmer/component';

export default class GridGutterSizesDemo extends Component {
  gutterSizes = [
    { size: 'none', text: 'None' },
    { size: 'xs', text: 'Extra small' },
    { size: 's', text: 'Small' },
    { size: 'm', text: 'Medium' },
    { size: 'l', text: 'Large (default)' },
    { size: 'xl', text: 'Extra large' },
  ];

  <template>
    {{#each this.gutterSizes as |gutter|}}
      <EuiFlexGrid class="flex-demo" @columns={{4}} @gutterSize={{gutter.size}}>
        <EuiFlexItem>{{gutter.text}}</EuiFlexItem>
        <EuiFlexItem>{{gutter.text}}</EuiFlexItem>
        <EuiFlexItem>{{gutter.text}}</EuiFlexItem>
        <EuiFlexItem>{{gutter.text}}</EuiFlexItem>
      </EuiFlexGrid>
      <EuiSpacer @size="m" />
    {{/each}}
  </template>
}
```
