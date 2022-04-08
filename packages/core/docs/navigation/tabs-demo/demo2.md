---
order: 2
---

# Tab sizes

<EuiText>
<p><strong>EuiTabs</strong> allow a <EuiCode>size</EuiCode> prop. In general you should always use the default (medium) size. The small size is best for when placing inside popovers or other small containers. Reserve using the large size for when using as primary page navigation, like inside of <a href="#/layout/page-header"><strong>EuiPageHeader</strong></a>.</p><p>You can also use the <EuiCode>expand</EuiCode> prop to evenly stretch each tab horizontally.</p>
</EuiText>

```hbs template
<div>
  <EuiPopover
    @ownFocus={{true}}
    @isOpen={{this.popover}}
    @anchorPosition='downLeft'
    @closePopover={{set this 'popover' false}}
  >
    <:button>
      <EuiButton
        @iconType='arrowDown'
        @iconSide='right'
        {{on 'click' (set this 'popover' true)}}
      >
        Show Popover
      </EuiButton>
    </:button>
    <:content>
      <EuiTabs>
        {{#each this.tabs as |tab|}}
          <EuiTab
            @isSelected={{eq this.selectedTab.id tab.id}}
            {{on 'click' (set this 'selectedTab' tab)}}
          >
            {{tab.name}}
          </EuiTab>
        {{/each}}
      </EuiTabs>
      <EuiSpacer />
      {{this.selectedTab.content}}
    </:content>
  </EuiPopover>
</div>
```

```js component
import Component from '@ember/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoTabsComponent extends Component {
  @tracked selectedTab;

  constructor() {
    super(...arguments);

    this.tabs = [
      {
        id: 'example1',
        name: 'Example 1',
        content: 'Example 1 content.'
      },
      {
        id: 'example2',
        name: 'Example 2',
        content: 'Example 2 content.'
      }
    ];

    this.selectedTab = this.tabs[0];
  }
}
```
