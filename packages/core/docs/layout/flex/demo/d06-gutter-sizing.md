---
order: 6
---

# Gutter sizing

<EuiText>

The `@gutterSize` arg can be applied to a parent `EuiFlexGroup` to adjust the spacing between child `EuiFlexItem`s.

</EuiText>

```hbs template
{{#each this.gutterSizes as |gutter|}}
  <EuiFlexGroup class="flex-demo" @gutterSize={{gutter.size}}>
    <EuiFlexItem>{{gutter.text}}</EuiFlexItem>
    <EuiFlexItem>{{gutter.text}}</EuiFlexItem>
    <EuiFlexItem>{{gutter.text}}</EuiFlexItem>
    <EuiFlexItem>{{gutter.text}}</EuiFlexItem>
  </EuiFlexGroup>
  <EuiSpacer @size="m" />
{{/each}}
```

```js component
import Component from '@glimmer/component';

export default class GutterSizesDemo extends Component {
  gutterSizes = [
    { size: 'none', text: 'None' },
    { size: 'xs', text: 'Extra small' },
    { size: 's', text: 'Small' },
    { size: 'm', text: 'Medium (default)' },
    { size: 'l', text: 'Large' },
    { size: 'xl', text: 'Extra large' },
  ];
}
```
