---
order: 4
---

# Text wrapping and tooltips

<EuiText>

Long item labels are truncated to one line by default. `@wrapText` on an item (or on **EuiListGroup**) wraps the text instead, for lists inside narrow containers.

Upstream's `showToolTips`, `toolTipText` and `toolTipProps` are not available on **EuiListGroup** yet; wrap an item's content in an **EuiToolTip** yourself when you need one.

</EuiText>

```hbs template
<EuiListGroup>
  <EuiListGroupItem @onClick={{this.noop}} @label="First item" />

  <EuiListGroupItem @onClick={{this.noop}} @label="Second item" />

  <EuiListGroupItem @onClick={{this.noop}}>
    <span>
      Third very, very long item that
      <strong>will surely</strong>
      force truncation
    </span>
  </EuiListGroupItem>

  <EuiListGroupItem
    @onClick={{this.noop}}
    @wrapText={{true}}
    @label="Fourth very long item with wrapping enabled, custom props, and will not force truncation."
  />
</EuiListGroup>
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class WrapTextDemo extends Component {
  @action
  noop() {}
}
```
