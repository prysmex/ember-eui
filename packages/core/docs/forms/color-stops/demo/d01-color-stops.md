---
order: 1
---

# Color stops

<EuiText>

A gradient from 0 to 100. The bar below previews the result with
`EuiColorPaletteDisplay`.

</EuiText>

```hbs template
<EuiFormRow @label="Heat map colors" @isInvalid={{this.isInvalid}} @error="A stop is incomplete">
  <EuiColorStops
    @label="Heat map colors"
    @colorStops={{this.stops}}
    @onChange={{this.setStops}}
    @min={{0}}
    @max={{100}}
  />
</EuiFormRow>
<EuiSpacer @size="s" />
<div style="max-width: 400px;">
  <EuiColorPaletteDisplay @palette={{this.stops}} @type="gradient" />
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ColorStopsDemo extends Component {
  @tracked stops = [
    { stop: 0, color: '#54B399' },
    { stop: 40, color: '#D6BF57' },
    { stop: 80, color: '#E7664C' },
  ];
  @tracked isInvalid = false;

  @action
  setStops(stops, isInvalid) {
    this.stops = stops;
    this.isInvalid = isInvalid;
  }
}
```
