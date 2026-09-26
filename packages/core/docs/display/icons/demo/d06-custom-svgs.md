---
order: 6
---

# Custom SVGs

<EuiText>

With [`@svg-jar/plugin`](https://github.com/svg-jar/plugin) in your
`vite.config.mjs` (see *Setup* above), importing an svg file gives an Ember
component. Pass it as `@type` (or `@iconType`) and it gets the size, color and
accessibility handling of any other icon.

Draw custom icons on a square canvas, ideally 16×16 for glyphs or 32×32 for
logos, and **remove `fill` attributes** from single color icons so they take
the text color and `@color`.

In a `.gjs`/`.gts` component the import can be used directly:

```gjs
import EuiIcon from '@ember-eui/core/components/eui-icon';
import Rocket from '../icons/rocket.svg';

<template>
  <EuiIcon @type={{Rocket}} @size="l" @title="Launch" />
</template>
```

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="l" @alignItems="center" @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type={{this.Rocket}} />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type={{this.Rocket}} @size="xl" @color="accent" @title="Launch" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiButton @iconType={{this.Rocket}} @fill={{true}}>Launch</EuiButton>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiBadge @iconType={{this.Leaf}} @color="success">Eco mode</EuiBadge>
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';

// app/icons/*.svg, turned into components by @svg-jar/plugin
import Rocket from 'site/icons/rocket.svg';
import Leaf from 'site/icons/leaf.svg';

export default class CustomSvgsDemo extends Component {
  Rocket = Rocket;
  Leaf = Leaf;
}
```
