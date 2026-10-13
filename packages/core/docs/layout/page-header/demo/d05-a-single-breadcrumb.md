---
order: 5
---

# A single breadcrumb

<EuiText>

A common pattern is to use a single breadcrumb to return the user to a listing page from which the current page was navigated to.

</EuiText>

```gjs component
import { EuiPageHeader, EuiButton } from '@ember-eui/core/components';
import Component from '@glimmer/component';

export default class PageHeaderReturnDemo extends Component {
  breadcrumbs = [
    {
      text: 'Return',
      color: 'primary',
      'aria-current': false,
      href: '#',
      onClick: (e) => e.preventDefault(),
    },
  ];

  <template>
    <EuiPageHeader
      @pageTitle="Page title"
      @description="Example of a description."
      @breadcrumbs={{this.breadcrumbs}}
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
