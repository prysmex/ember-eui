---
order: 14
---

# Responsive flex grids

<EuiText>

`EuiFlexGrid` is responsive by default, stacking items vertically on smaller screens. Should you want to customize the number of items on small or large screens, apply `@responsive={{false}}` and then conditionally pass a column number based on the current breakpoint.

Upstream does this with the `useIsWithinBreakpoints` hook. Here a small modifier tracks a media query for the `xs` and `s` breakpoints (below 768px).

</EuiText>

```gjs component
import { EuiFlexGrid, EuiFlexItem } from '@ember-eui/core/components';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { modifier } from 'ember-modifier';

export default class ResponsiveGridDemo extends Component {
  @tracked isMobile = false;

  watchMobile = modifier(() => {
    const query = window.matchMedia('(max-width: 767px)');
    const update = () => {
      this.isMobile = query.matches;
    };
    update();
    query.addEventListener('change', update);
    return () => query.removeEventListener('change', update);
  });

  <template>
    <EuiFlexGrid
      class="flex-demo"
      @responsive={{false}}
      @columns={{if this.isMobile 2 4}}
      {{this.watchMobile}}
    >
      <EuiFlexItem>One</EuiFlexItem>
      <EuiFlexItem>Two</EuiFlexItem>
      <EuiFlexItem>Three</EuiFlexItem>
      <EuiFlexItem>Four</EuiFlexItem>
      <EuiFlexItem>Five</EuiFlexItem>
      <EuiFlexItem>Six</EuiFlexItem>
    </EuiFlexGrid>
  </template>
}
```
