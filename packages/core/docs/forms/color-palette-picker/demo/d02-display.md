---
order: 2
---

# Palette display

<EuiText>

`EuiColorPaletteDisplay` in its three sizes, as fixed blocks, as a
gradient, and with color stops (the blocks are as wide as the distance
between stops).

</EuiText>

```hbs template
<EuiFlexGroup @direction="column" @gutterSize="m">
  <EuiFlexItem><EuiColorPaletteDisplay @palette={{this.colors}} @size="xs" /></EuiFlexItem>
  <EuiFlexItem><EuiColorPaletteDisplay @palette={{this.colors}} /></EuiFlexItem>
  <EuiFlexItem><EuiColorPaletteDisplay @palette={{this.colors}} @size="m" /></EuiFlexItem>
  <EuiFlexItem><EuiColorPaletteDisplay @palette={{this.colors}} @type="gradient" /></EuiFlexItem>
  <EuiFlexItem><EuiColorPaletteDisplay @palette={{this.stops}} @title="Load" /></EuiFlexItem>
  <EuiFlexItem><EuiColorPaletteDisplay @palette={{this.stops}} @type="gradient" /></EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';

export default class PaletteDisplayDemo extends Component {
  colors = ['#54B399', '#6092C0', '#D36086', '#9170B8', '#D6BF57'];

  stops = [
    { stop: 10, color: '#54B399' },
    { stop: 60, color: '#D6BF57' },
    { stop: 100, color: '#E7664C' },
  ];
}
```
