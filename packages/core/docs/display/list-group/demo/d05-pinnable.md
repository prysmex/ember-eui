---
order: 5
---

# Pinnable list group

<EuiText>

Hover an item and click its pin: it moves to the "Pinned" list, where the
pin always shows. Click it there to unpin. Items with `pinnable: false`
have no pin.

</EuiText>

```hbs template
<EuiPanel style="max-width: 320px;">
  <EuiTitle @size="xxs"><h3>Pinned</h3></EuiTitle>
  {{#if this.pinnedItems.length}}
    <EuiPinnableListGroup
      @listItems={{this.pinnedItems}}
      @onPinClick={{this.togglePin}}
      @color="subdued"
      @size="s"
    />
  {{else}}
    <EuiText @size="xs" @color="subdued"><p>Nothing pinned yet.</p></EuiText>
  {{/if}}
  <EuiHorizontalRule @margin="s" />
  <EuiTitle @size="xxs"><h3>Analytics</h3></EuiTitle>
  <EuiPinnableListGroup
    @listItems={{this.unpinnedItems}}
    @onPinClick={{this.togglePin}}
    @color="subdued"
    @size="s"
  />
</EuiPanel>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class PinnableDemo extends Component {
  @tracked items = [
    { label: 'Discover', href: '#discover', pinned: true },
    { label: 'Dashboards', href: '#dashboards' },
    { label: 'Visualize library', href: '#visualize' },
    { label: 'Maps', href: '#maps' },
    { label: 'Overview', href: '#overview', pinnable: false },
  ];

  get pinnedItems() {
    return this.items.filter((item) => item.pinned);
  }

  get unpinnedItems() {
    return this.items.filter((item) => !item.pinned);
  }

  @action
  togglePin(clicked) {
    this.items = this.items.map((item) =>
      item.label === clicked.label ? { ...item, pinned: !item.pinned } : item,
    );
  }
}
```
