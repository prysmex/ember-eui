---
order: 4
---

# Text wrapping and tooltips

<EuiText>

Optional arguments `@showToolTip` and `@wrapText` can be used to augment the display of list items. Use these when lists are inside small containers where it is likely that the content will be truncated. `@showToolTips` on **EuiListGroup** turns the tooltip on for all of its items.

Similarly, `@toolTipText` can be used to provide tooltip text. By default, the tooltip has the same content as the label: `@label`, or the block's content (as the third item shows, rich content included). Truncated labels without a tooltip get their text as `title`.

`@wrapText` on **EuiListGroup** only applies to its `@listItems` (as upstream); items in the block set their own `@wrapText`.

You can also use `@toolTipProps`, an object of **EuiToolTip** arguments, to customize tooltip placement, title and other behaviors.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { EuiListGroup, EuiListGroupItem } from '@ember-eui/core/components';

export default class WrapTextDemo extends Component {
  @action
  noop() {}

  fourthToolTip = { position: 'top', title: 'Title of record' };

  <template>
    <EuiListGroup @showToolTips={{true}}>
      <EuiListGroupItem
        @onClick={{this.noop}}
        @label="First item"
        @toolTipText="This is tooltip text"
      />

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
        @toolTipProps={{this.fourthToolTip}}
      />
    </EuiListGroup>
  </template>
}
```

