# Demo

```hbs template
<EuiSpacer @size="xxl" />
<EuiTitle @size="s">
  Simple tabs with
  <b>
    isSelected
  </b>
  and
  <b>
    display = condensed
  </b>
</EuiTitle>
<EuiTabs @display="condensed" as |EuiTab|>
  <EuiTab @isSelected={{true}}>
    Example 1
  </EuiTab>
  <EuiTab>
    Example 2
  </EuiTab>
  <EuiTab>
    Example 3
  </EuiTab>
</EuiTabs>
<EuiSpacer @size="xxl" />
<EuiTitle @size="s">
  Simple tabs with
  <b>
    disabled
  </b>
  and
  <b>
    expand = true
  </b>
</EuiTitle>
<EuiTabs @expand={{true}} as |EuiTab|>
  <EuiTab @disabled={{true}}>
    Example 1
  </EuiTab>
  <EuiTab>
    Example 2
  </EuiTab>
</EuiTabs>
<EuiSpacer @size="xxl" />
<EuiTitle @size="s">
  Tabbed content
</EuiTitle>
<EuiTabs::EuiTabbedContent @tabs={{this.tabsItems1}} />
<EuiSpacer @size="xxl" />
<EuiTitle @size="s">
  Tabbed content with
  <b>
    onTabClick
  </b>
</EuiTitle>
<EuiTabs::EuiTabbedContent @tabs={{this.tabsItems2}} @onTabClick={{this.sayMyName}} />
<EuiSpacer @size="xxl" />
<EuiTitle @size="s">
  Tabbed content with
  <b>
    initialSelectedTab
  </b>
</EuiTitle>
<EuiTabs::EuiTabbedContent
  @tabs={{this.tabsItems2}}
  @initialSelectedTab={{object-at 2 this.tabsItems2}}
/>
<EuiSpacer @size="xxl" />
<EuiTitle @size="s">
  Tabbed content with
  <b>
    selectedTab
  </b>
</EuiTitle>
<p>
  This is used if you want to control the tabs from the outside, however the internal state is not propagated to the
  outside
</p>
<EuiSpacer />
<button type="button" class="euiButton euiButton--primary" {{on "click" this.cycleTabs}}>
  Next tab
</button>
Outer selected tab:
{{get (object-at this.tabsIndex2 this.tabsItems2) "name"}}
<EuiTabs::EuiTabbedContent
  @tabs={{this.tabsItems2}}
  @selectedTab={{object-at this.tabsIndex2 this.tabsItems2}}
/>
```


```js component
import Component from '@ember/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class DemoTabsComponent extends Component {
  @tracked tabsIndex2 = 0;

  constructor() {
    super(...arguments);

    this.tabsItems1 = [
      {
        id: 'example1',
        name: 'Example 1',
        content: 'Example 1 content.',
      },
      {
        id: 'example2',
        name: 'Example 2',
        content: 'Example 2 content.',
      },
    ];

    this.tabsItems2 = [
      {
        id: 'one',
        name: 'Click me 1!',
        content: 'Same ol\' 1 content.',
      },
      {
        id: 'two',
        name: 'Click me 2!',
        content: 'Same ol\' 2 content.',
      },
      {
        id: 'three',
        name: 'Click me 3!',
        content: 'Same ol\' 3 content.',
      }
    ];
  }

  sayMyName (tab) {
    alert(`I am ${tab.name || tab.id}`);
  }

  @action
  cycleTabs () {
    this.tabsIndex2++;

    if (this.tabsIndex2 >= this.tabsItems2.length) {
      this.tabsIndex2 = 0;
    }
  }
}


```