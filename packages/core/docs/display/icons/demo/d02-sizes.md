---
order: 2
---

# Sizes

<EuiText>

`@size` sets a square size: `s` 12px, `m` 16px (default), `l` 24px, `xl` 32px
and `xxl` 40px. `original` keeps the width and height of the svg itself.

Glyphs are drawn for 16px; logos, app and machine learning icons for 32px, so
use `xl` for those. Non-`original` sizes assume a square `viewBox`.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="xl" @alignItems="flexEnd" @wrap={{true}}>
  {{#each this.sizes as |size|}}
    <EuiFlexItem @grow={{false}}>
      <EuiFlexGroup @direction="column" @alignItems="center" @gutterSize="s">
        <EuiFlexItem @grow={{false}}>
          <EuiIcon @type="logoElasticsearch" @size={{size.name}} />
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiCode>@size="{{size.name}}"</EuiCode>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiText @size="xs" @color="subdued">{{size.pixels}}</EuiText>
        </EuiFlexItem>
      </EuiFlexGroup>
    </EuiFlexItem>
  {{/each}}
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';

export default class IconSizesDemo extends Component {
  sizes = [
    { name: 's', pixels: '12px' },
    { name: 'm', pixels: '16px' },
    { name: 'l', pixels: '24px' },
    { name: 'xl', pixels: '32px' },
    { name: 'xxl', pixels: '40px' },
    { name: 'original', pixels: 'svg size' },
  ];
}
```
