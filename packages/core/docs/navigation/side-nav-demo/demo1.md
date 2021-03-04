# Demo

```hbs template
<EuiSideNav
  @mobileTitle="Test Mobile Title"
  @isOpenMobile={{true}}
  @items={{this.sideNavItems}}
  @selectedItem={{this.selectedItem}}
/>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class DemoSideNavComponent extends Component {
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
      onClick,
    };
  }

  constructor() {
    super(...arguments);

    let createItem = this.createItem.bind(this);

    this.sideNavItems = [
      createItem('Elasticsearch', {
        icon: 'logoElasticsearch',
        items: [
          createItem('Data sources'),
          createItem('Users'),
          createItem('Roles'),
          createItem('Watches'),
          createItem(
            'Extremely long title will become truncated when the browser is narrow enough'
          ),
        ],
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
                  }),
                  createItem('Lion stuff', {
                    icon: 'stats',
                    items: [
                      createItem('Hello sstuff', {
                        icon: 'logoGolang',
                      }),
                    ],
                  }),
                ],
              }),
              createItem('Visualizations'),
            ],
          }),
          createItem('Index Patterns'),
          createItem('Saved Objects'),
          createItem('Reporting'),
        ],
      }),
      createItem('Logstash', {
        icon: 'logoLogstash',
        items: [createItem('Pipeline viewer')],
      }),
    ];
  }
}

```