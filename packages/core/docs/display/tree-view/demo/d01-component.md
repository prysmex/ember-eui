---
order: 1
---

# Component

<EuiCallOut @title="Accessibility recommendation" @iconType="accessibility">
  Provide a descriptive <EuiCode>aria-label</EuiCode> for each tree view. This component also builds in keyboard navigation allowing users to traverse the tree using the arrow keys, spacebar, and return.
</EuiCallOut>

<EuiSpacer />

<EuiText>

A node's `icon` and `iconWhenExpanded` take an icon type, or a component for a custom icon such as an **EuiToken** (upstream takes an element), as the nodes with a token do here.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiToken, EuiTreeView } from '@ember-eui/core/components';

const tokenIcon = (token) => <template><EuiToken @iconType={{token}} /></template>;

export default class extends Component {
  items = [
    {
      label: 'Item One',
      id: 'item_one',
      icon: 'folder',
      iconWhenExpanded: 'folderOpen',
      isExpanded: true,
      children: [
        {
          label: 'Item A',
          id: 'item_a',
          icon: 'document',
        },
        {
          label: 'Item B',
          id: 'item_b',
          icon: 'chevronSingleRight',
          iconWhenExpanded: 'chevronSingleDown',
          children: [
            {
              label: 'A Cloud',
              id: 'item_cloud',
              icon: tokenIcon('tokenConstant'),
            },
            {
              label: "I'm a Bug",
              id: 'item_bug',
              icon: tokenIcon('tokenEnum'),
              callback: () => {},
            },
          ],
        },
        {
          label: 'Item C',
          id: 'item_c',
          icon: 'chevronSingleRight',
          iconWhenExpanded: 'chevronSingleDown',
          children: [
            {
              label: 'Another Cloud',
              id: 'item_cloud2',
              icon: tokenIcon('tokenConstant'),
            },
            {
              label:
                'This one is a really long string that we will check truncates correctly',
              id: 'item_bug2',
              icon: tokenIcon('tokenEnum'),
              callback: () => {},
            },
          ],
        },
      ],
    },
    {
      label: 'Item Two',
      id: 'item_two',
    },
  ];

  <template>
    <div style='width: 20rem'>
      <EuiTreeView @items={{this.items}} aria-label='Sample Folder Tree' />
    </div>
  </template>
}
```

