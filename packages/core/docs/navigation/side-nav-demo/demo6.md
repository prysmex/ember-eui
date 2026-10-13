---
order: 6
---

# Heading block (Ember EUI extension)

<EuiText>

Besides `@heading`, the `<:heading>` block renders any content as the heading. Items also accept `truncate`, `disabled`, `emphasize` and `icon`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiIcon, EuiSideNav, EuiSpacer } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked sideNavItems = [];
  @tracked selectedItem = 'Elasticsearch';

  createItem(name = '', data) {
    let onClick = () => {
      this.selectedItem = name;
    };
    return {
      ...data,
      id: name,
      name,
      onClick
    };
  }

  constructor() {
    super(...arguments);

    let createItem = this.createItem.bind(this);

    this.sideNavItems = [
      createItem('Elasticsearch', {
        icon: 'logoElasticsearch',
        items: [
          createItem('Data sources', { disabled: true }),
          createItem('Users'),
          createItem('Roles'),
          createItem('Watches'),
          createItem(
            'Extremely long title will become truncated when the browser is narrow enough',
            { truncate: true }
          )
        ]
      }),
      createItem('Kibana', {
        icon: 'logoKibana',
        items: [
          createItem('Advanced settings', {
            items: [
              createItem('General'),
              createItem('Timelion', {
                items: [
                  createItem('Time stuff', {
                    icon: 'clock',
                    emphasize: true
                  }),
                  createItem('Lion stuff', {
                    icon: 'stats',
                    items: [
                      createItem('Hello sstuff', {
                        icon: 'logoGolang',
                        disabled: true
                      })
                    ]
                  })
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
        icon: 'logoLogstash',
        items: [createItem('Pipeline viewer')]
      })
    ];
  }

  <template>
    <EuiSideNav
      @mobileTitle='Mobile Title'
      @heading='Title'
      @isOpenOnMobile={{true}}
      @items={{this.sideNavItems}}
      @selectedItem={{this.selectedItem}}
      @truncate={{true}}
      {{! you can also truncate per item }}
    />

    <EuiSpacer />
    <EuiSideNav
      @isOpenOnMobile={{true}}
      @items={{this.sideNavItems}}
      @selectedItem={{this.selectedItem}}
      @truncate={{true}}
      {{! you can also truncate per item }}
    >
      <:heading>
        <EuiIcon @type='faceHappy' />
        Header!
      </:heading>
    </EuiSideNav>
  </template>
}
```
