---
order: 1
---

# A full page with everything

<EuiText>
  EUI provides a family of components using the
  <EuiCode>EuiPage</EuiCode>
  prefix that work together to build consistent page layouts that work
  responsively.<br />
  <ul>
    <li><strong>EuiPage</strong>
      and
      <strong>EuiPageBody</strong>
      provide the overall wrapper with a column flex display.</li>
    <li><strong>EuiPageSideBar</strong>
      provides a way to add side navigation that can be made sticky to scroll
      independent of the page content. See
      <strong>EuiSideNav</strong>
      for contents.</li>
    <li><strong>EuiPageHeader</strong>
      provides a title, description, section for actions and possible tabs.</li>
    <li><strong>EuiPageContent</strong>
      provides the main content container and extends
      <strong>EuiPanel</strong>.</li>
    <li><strong>EuiPageContentBody</strong>
      wraps the content that comes after the page header.</li>
  </ul>
  Or you can use the provided
  <strong>EuiPageTemplate</strong>, which is simply a shortcut for creating the
  different types of page layout patterns described in these docs. It is
  somewhat opinionated, but still has the ability to customize most of the inner
  components with props like
  <EuiCode>pageSideBarProps</EuiCode>
  and
  <EuiCode>pageContentProps</EuiCode>.
</EuiText>

```hbs template
<EuiPageTemplate
  @grow={{true}}
  @pageHeader={{hash
    iconType='logoElastic'
    pageTitle='Page Title'
    tabs=this.tabs
  }}
  @hasBottomBarBlock={{this.showing}}
>
  <:pageSideBar>
    <EuiLoadingContent @lines={{8}} />
  </:pageSideBar>
  <:pageHeaderRightSideItems as |Item|>
    <Item>
      <EuiButton>
        Go Full Screen
      </EuiButton>
    </Item>
  </:pageHeaderRightSideItems>
  <:default>
    <EuiLoadingContent @lines={{16}} />
  </:default>
  <:bottomBar>
    Bottom bar
  </:bottomBar>
</EuiPageTemplate>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class DemoIconComponent extends Component {
  @tracked selectedTab = true;
  @tracked showing = false;

  get tabs() {
    return [
      {
        label: 'Tab 1',
        isSelected: this.selectedTab,
        onClick: this.setShowBottomBar.bind(this, true)
      },
      {
        label: 'Tab 2',
        isSelected: !this.selectedTab,
        onClick: this.setShowBottomBar.bind(this, false)
      }
    ];
  }

  setShowBottomBar = (val) => {
    this.selectedTab = val;
    this.showing = !val;
  };
}
```
