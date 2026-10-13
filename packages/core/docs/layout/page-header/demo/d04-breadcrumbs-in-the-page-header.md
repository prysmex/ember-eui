---
order: 4
---

# Breadcrumbs in the page header

<EuiText>

Breadcrumbs are useful for tracking in-page flows that **are not part of the entire application architecture**. To make this easy `EuiPageHeader` provides a `@breadcrumbs` arg that accepts the same configuration as `EuiBreadcrumbs`'s `@breadcrumbs`. `@breadcrumbProps` forwards `className`, `EuiBreadcrumbs` arguments and attributes such as `aria-label` or `data-test-subj` (`@tabsProps`, `@pageTitleProps`, `@iconProps` and `@rightSideGroupProps` work the same way).

</EuiText>

```gjs component
import { EuiPageHeader, EuiButton } from '@ember-eui/core/components';
import Component from '@glimmer/component';

export default class PageHeaderBreadcrumbsDemo extends Component {
  breadcrumbs = [
    { text: 'Breadcrumb 1', href: '#', onClick: (e) => e.preventDefault() },
    { text: 'Breadcrumb 2', href: '#', onClick: (e) => e.preventDefault() },
    { text: 'Current', href: '#', onClick: (e) => e.preventDefault() },
  ];

  breadcrumbProps = { 'aria-label': 'Page breadcrumbs', className: 'testClass1 testClass2', 'data-test-subj': 'pageBreadcrumbs' };

  <template>
    <EuiPageHeader
      @pageTitle="Page title"
      @description="Example of a description."
      @breadcrumbs={{this.breadcrumbs}}
      @breadcrumbProps={{this.breadcrumbProps}}
    >
      <:rightSideItems as |Item|>
        <Item>
          <EuiButton @fill={{true}}>Add something</EuiButton>
        </Item>
        <Item>
          <EuiButton>Do something</EuiButton>
        </Item>
      </:rightSideItems>
    </EuiPageHeader>
  </template>
}
```
