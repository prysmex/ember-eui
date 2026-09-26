---
order: 2
---

# Indeterminate (select all)

<EuiText>

A "select all" checkbox is checked when every item is, unchecked when none
is, and `@indeterminate` when only some are. Clicking it selects or clears
everything.

</EuiText>

```hbs template
<EuiCheckbox
  @label="All notifications"
  @checked={{this.allSelected}}
  @indeterminate={{this.someSelected}}
  {{on "change" this.toggleAll}}
/>
<div style="padding-left: 24px;">
  {{#each this.items as |item|}}
    <EuiCheckbox
      @label={{item.label}}
      @checked={{get this.selected item.id}}
      {{on "change" (fn this.toggle item.id)}}
    />
  {{/each}}
</div>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class IndeterminateDemo extends Component {
  items = [
    { id: 'email', label: 'Email' },
    { id: 'sms', label: 'Text messages' },
    { id: 'push', label: 'Push notifications' },
  ];

  @tracked selected = { email: true };

  get count() {
    return this.items.filter((item) => this.selected[item.id]).length;
  }

  get allSelected() {
    return this.count === this.items.length;
  }

  get someSelected() {
    return this.count > 0 && !this.allSelected;
  }

  @action
  toggle(id) {
    this.selected = { ...this.selected, [id]: !this.selected[id] };
  }

  @action
  toggleAll() {
    const value = !this.allSelected;

    this.selected = Object.fromEntries(this.items.map((item) => [item.id, value]));
  }
}
```
