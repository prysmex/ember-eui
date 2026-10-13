---
order: 5
---

# Colors

<EuiText>

**EuiProgress** supports a few options for `@color`. You can pass any value from our basic color set or from our visualization palette (`vis0` through `vis9`).

Additionally, you can pass any valid color string like a hex value or named color. Each `@valueText` renders with a high contrast version of the color.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiFlexGroup, EuiFlexItem, EuiProgress, EuiSpacer } from '@ember-eui/core/components';

export default class ProgressColorsDemo extends Component {
  mainColors = ['primary', 'success', 'warning', 'danger', 'subdued', 'accent'];
  visColors = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map((i) => `vis${i}`);

  <template>
    <EuiFlexGroup>
      <EuiFlexItem>
        {{#each this.mainColors as |color|}}
          <EuiProgress @label={{color}} @valueText={{true}} @value={{80}} @max={{100}} @color={{color}} @size="m" />
          <EuiSpacer @size="s" />
        {{/each}}
      </EuiFlexItem>
      <EuiFlexItem>
        {{#each this.visColors as |color|}}
          <EuiProgress @label={{color}} @valueText={{true}} @value={{80}} @max={{100}} @color={{color}} @size="m" />
          <EuiSpacer @size="s" />
        {{/each}}
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiProgress @valueText={{true}} @label="#32CD32" @color="#32CD32" @value={{80}} @max={{100}} @size="m" />
        <EuiSpacer @size="s" />
        <EuiProgress @valueText={{true}} @label="mediumslateblue" @color="mediumslateblue" @value={{80}} @max={{100}} @size="m" />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```

