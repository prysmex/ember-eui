---
order: 3
---

# Complex side nav

<EuiText>

**EuiSideNav** also supports multiple top level sections and deeply-nested tree-based data.

We recommend being consistent with the use of the root level item and whether it is used solely for labelling a section. Intermixing linked and non-linked root items will confuse the user. Stay consistent throughout your entire application and platform.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSideNav } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked isSideNavOpenOnMobile = false;
  @tracked selectedItemName = 'Time stuff';

  @action
  toggleOpenOnMobile() {
    this.isSideNavOpenOnMobile = !this.isSideNavOpenOnMobile;
  }

  // NOTE: Duplicate `name` values will cause `id` collisions.
  createItem = (name, data = {}) => ({
    id: name.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
    name,
    isSelected: this.selectedItemName === name,
    onClick: () => {
      this.selectedItemName = name;
    },
    ...data
  });

  get sideNav() {
    const createItem = this.createItem;

    return [
      createItem('Elasticsearch', {
        onClick: undefined,
        icon: 'logoElasticsearch',
        items: [
          createItem('Data sources'),
          createItem('Users'),
          createItem('Roles'),
          createItem('Watches'),
          createItem(
            'Extremely long title will become truncated when the browser is narrow enough'
          )
        ]
      }),
      createItem('Kibana', {
        onClick: undefined,
        icon: 'logoKibana',
        items: [
          createItem('Advanced settings', {
            items: [
              createItem('General', { disabled: true }),
              createItem('Timelion', {
                items: [
                  createItem('Time stuff', { icon: 'clock' }),
                  createItem('Lion stuff', { icon: 'stats' })
                ]
              }),
              createItem('Visualizations')
            ]
          }),
          createItem('Index Patterns'),
          createItem('Saved Objects'),
          createItem('Reporting')
        ]
      }),
      createItem('Logstash', {
        onClick: undefined,
        icon: 'logoLogstash',
        items: [createItem('Pipeline viewer')]
      })
    ];
  }

  <template>
    <EuiSideNav
      aria-label="Complex example"
      @mobileTitle="Navigate within $APP_NAME"
      @toggleOpenOnMobile={{this.toggleOpenOnMobile}}
      @isOpenMobile={{this.isSideNavOpenOnMobile}}
      @items={{this.sideNav}}
      style="width: 192px"
    />
  </template>
}
```
