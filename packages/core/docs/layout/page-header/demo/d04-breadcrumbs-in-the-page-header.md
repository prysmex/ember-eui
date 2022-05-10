---
order: 4
---

# Breadcrumbs in the page header

<EuiText>
	<a href="#">Breadcrumbs</a> are useful for tracking in-page flows that <strong>are not part of the entire application architecture</strong>. To make this easy <strong>EuiPageHeader</strong> provides a <EuiCode>breadcrumbs</EuiCode> prop that accepts the same configuration as <EuiCode>EuiBreadrumbs.breadcrumbs</EuiCode>.
</EuiText>

```hbs template
<!-- example 1 -->
<EuiPageHeader
  @bottomBorder={{true}}
  @pageTitle='Page title'
  @description='Example of a description.'
  @breadcrumbs={{this.breadcrumbsExample1}}
>
  <:rightSideItems>
    <EuiFlexItem>
      <EuiButton @fill={{true}}>Add something</EuiButton>
    </EuiFlexItem>
    <EuiFlexItem>
      <EuiButton>Do something</EuiButton>
    </EuiFlexItem>
  </:rightSideItems>
</EuiPageHeader>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class AccordionDemo1Component extends Component {
  breadcrumbsExample1 = [
    {
      text: 'Breadcrumb 1',
      href: '#',
      onClick: (e) => e.preventDefault()
    },
    {
      text: 'Breadcrumb 2',
      href: '#',
      onClick: (e) => e.preventDefault()
    },
    {
      text: 'Current',
      href: '#',
      onClick: (e) => e.preventDefault()
    }
  ];
}
```
