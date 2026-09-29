---
order: 2
---

# Single selection and exclusions

<EuiText>

On the left, `@singleSelection="always"`: exactly one option. On the right,
`@allowExclusions`: clicking a checked option excludes it (a cross),
clicking it again clears it, e.g. for "include / exclude" filters.

</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem>
    <EuiSelectable
      @options={{this.sizes}}
      @onChange={{this.setSizes}}
      @singleSelection="always"
      @listProps={{hash bordered=true}}
      aria-label="Size"
    />
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiSelectable
      @options={{this.tags}}
      @onChange={{this.setTags}}
      @allowExclusions={{true}}
      @listProps={{hash bordered=true}}
      aria-label="Tags"
    />
  </EuiFlexItem>
</EuiFlexGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class SelectableSingle extends Component {
  @tracked sizes = [
    { label: 'Small' },
    { label: 'Medium', checked: 'on' },
    { label: 'Large' },
  ];

  @tracked tags = [
    { label: 'bug', checked: 'on' },
    { label: 'enhancement' },
    { label: 'wontfix', checked: 'off' },
    { label: 'documentation' },
  ];

  @action
  setSizes(options) {
    this.sizes = options;
  }

  @action
  setTags(options) {
    this.tags = options;
  }
}
```
