---
order: 1
---

# Basic Page

<EuiText>
  Page layouts are modular and fit together in a precise manner, though certain
  parts can also be added or removed as needed. EUI provides both the indivdual
  page components and an over-arching template for easily creating some
  pre-defined layouts.
</EuiText>
<EuiSpacer />
<EuiCallOut
  @title='The following examples showcase the both the template and custom built
    usages of the page components.'
  @iconType='document'
>
  <:body>
    You'll find the code for each in their own tab and if you go to full screen,
    you can see how they would behave in a typical application layout.
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiHorizontalRule />
<EuiTitle>
  A full page with everything
</EuiTitle>
<EuiSpacer />
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
    rightSideItems=(array (component 'eui-button-title' title='Go full screen'))
    tabs=this.tabs
  }}
  @pageSideBar={{component 'eui-loading-content' lines=8}}
>
  <EuiLoadingContent @lines={{16}} />
</EuiPageTemplate>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoIconComponent extends Component {
  tabs = [
    { label: 'Tab 1', isSelected: true },
    {
      label: 'Tab 2',
      onClick: this.setShowBottomBar
    }
  ];
  @tracked showing = false;

  @action
  setSHowBottomBar() {
    this.showing = !this.showing;
  }
}
```
