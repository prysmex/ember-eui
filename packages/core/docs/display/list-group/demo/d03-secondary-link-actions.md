---
order: 3
---

# Secondary link actions

<EuiText>

The `@extraAction` argument adds a secondary icon button to any list item. It accepts several properties of its own, including `color`, `onClick`, `iconType`, and `alwaysShow`, and can be used for actions such as pinning, adding to favorites, or deleting an item.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiListGroup, EuiListGroupItem } from '@ember-eui/core/components';

export default class ExtraActionDemo extends Component {
  @tracked favorites = ['link2'];

  rows = [
    { id: 'link1', iconType: 'bullseye', isActive: true },
    { id: 'link2', iconType: 'visualizeApp' },
    { id: 'link3', iconType: 'lensApp' },
    { id: 'link4', iconType: 'broom', actionDisabled: true },
    { id: 'link5', iconType: 'brush', isDisabled: true, plain: true },
  ];

  get items() {
    return this.rows.map((row) => {
      const isFavorite = this.favorites.includes(row.id);
      return {
        iconType: row.iconType,
        isActive: row.isActive,
        isDisabled: row.isDisabled,
        extraAction: {
          color: 'text',
          onClick: () => this.toggle(row.id),
          iconType: !row.plain && isFavorite ? 'starFilled' : 'starEmpty',
          iconSize: 's',
          'aria-label': `Favorite ${row.id}`,
          alwaysShow: !row.plain && isFavorite,
          isDisabled: row.actionDisabled,
        },
      };
    });
  }

  @action
  toggle(id) {
    this.favorites = this.favorites.includes(id)
      ? this.favorites.filter((f) => f !== id)
      : [...this.favorites, id];
  }

  @action
  noop() {}

  <template>
    <EuiListGroup @maxWidth={{288}}>
      {{#each this.items as |item|}}
        <EuiListGroupItem
          @iconType={{item.iconType}}
          @label="EUI button link"
          @onClick={{this.noop}}
          @isActive={{item.isActive}}
          @isDisabled={{item.isDisabled}}
          @extraAction={{item.extraAction}}
        />
      {{/each}}
    </EuiListGroup>
  </template>
}
```

