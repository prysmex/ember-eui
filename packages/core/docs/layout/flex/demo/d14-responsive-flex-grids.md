---
order: 14
---

# Responsive flex grids

<EuiText>

`EuiFlexGrid` is responsive by default, stacking items vertically on smaller screens. Should you want to customize the number of items on small or large screens, apply `@responsive={{false}}` and then conditionally pass a column number based on the current breakpoint.

Upstream does this with the `useIsWithinBreakpoints` hook. Here the `use-is-within-breakpoints` modifier reports whether the window is within the given breakpoints.

</EuiText>

```hbs template
<EuiFlexGrid
  class="flex-demo"
  @responsive={{false}}
  @columns={{if this.isMobile 2 4}}
  {{use-is-within-breakpoints
    sizes=(array "xs" "s")
    setIsWithinBreakpointsValue=this.setIsMobile
  }}
>
  <EuiFlexItem>One</EuiFlexItem>
  <EuiFlexItem>Two</EuiFlexItem>
  <EuiFlexItem>Three</EuiFlexItem>
  <EuiFlexItem>Four</EuiFlexItem>
  <EuiFlexItem>Five</EuiFlexItem>
  <EuiFlexItem>Six</EuiFlexItem>
</EuiFlexGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ResponsiveGridDemo extends Component {
  @tracked isMobile = false;

  @action
  setIsMobile(value) {
    this.isMobile = value;
  }
}
```
