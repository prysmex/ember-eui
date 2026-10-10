---
order: 6
---

# A simple page with tabs

<EuiText>
  When leaving off the <strong>EuiPageSideBar</strong>, we recommend a slightly different configuration by pulling the page header out of the <strong>EuiPageContent</strong> and removing the shadow from <strong>EuiPageContent</strong>.
</EuiText>
<EuiSpacer />
<EuiCallOut>
  <:title>
    This layout will automatically be achieved through <strong>EuiPageTemplate</strong> by omitting the <EuiCode>&lt;:pageSideBar&gt;</EuiCode> block.
  </:title>
</EuiCallOut>

```hbs template
<EuiPageTemplate
  @grow={{true}}
  @pageHeader={{hash
    iconType='logoElastic'
    pageTitle='Page Title'
    tabs=this.tabs
  }}
>
  <:pageHeaderRightSideItems as |Item|>
    <Item>
      <EuiButton>
        Go to full screen
      </EuiButton>
    </Item>
  </:pageHeaderRightSideItems>
  <:default>
    <EuiText><p>Selected section: {{this.selectedTab}}</p></EuiText>
    <EuiLoadingContent @lines={{16}} />
  </:default>
</EuiPageTemplate>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class PageTabsDemo extends Component {
  @tracked selectedTab = 'overview';

  get tabs() {
    return [
      { label: 'Overview', isSelected: this.selectedTab === 'overview', onClick: () => this.selectTab('overview') },
      { label: 'Activity', isSelected: this.selectedTab === 'activity', onClick: () => this.selectTab('activity') }
    ];
  }

  selectTab = (tab) => {
    this.selectedTab = tab;
  };
}
```
