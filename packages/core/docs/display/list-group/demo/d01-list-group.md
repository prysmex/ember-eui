---
order: 1
---

# List group

<EuiText>

The **EuiListGroup** component is used to present **EuiListGroupItems** in a neatly formatted list. Use `@bordered` for a bordered presentation.

</EuiText>

```hbs template
<EuiFlexGroup @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiSwitch @label="Show as bordered" @checked={{this.showBorder}} @onChange={{this.toggleBorder}} />
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer @size="l" />

<EuiListGroup @bordered={{this.showBorder}}>
  <EuiListGroupItem @onClick={{this.noop}} @label="First item" />
  <EuiListGroupItem @onClick={{this.noop}} @label="Second item" />
  <EuiListGroupItem @onClick={{this.noop}} @label="Third item" @isActive={{true}} />
  <EuiListGroupItem @onClick={{this.noop}} @label="Fourth item" @isDisabled={{true}} />
</EuiListGroup>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class ListGroupDemo extends Component {
  @tracked showBorder = false;

  @action
  toggleBorder() {
    this.showBorder = !this.showBorder;
  }

  @action
  noop() {}
}
```
