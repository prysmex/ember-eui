---
order: 1
---

<EuiText>
	<p>
		<strong>EuiBreadcrumbs</strong> let the user track their progress within and back out of a UX flow and work well when used in combination with <strong>EuiPageHeader</strong>. They are meant to be used at lower page level flows, while <strong>EuiHeaderBreadcrumbs</strong> should be used for application-wide navigation.
  </p>

  <p>
  <strong>EuiBreadcrumbs</strong> requires an array of <strong>EuiBreadcrumb</strong> objects as <EuiCode>breadcrumbs</EuiCode> and handles truncation, including middle-truncation in the case of many items, and mobile responsiveness. Each item accepts an <EuiCode>href</EuiCode> prop, though we recommend the last item represent the current page and therefore the link is unnecessary.
  </p>

</EuiText>
<EuiSpacer/>

<EuiCallOut @iconType='accessibility' @color='warning'>
  <:title>
    For accessibility, it is highly recommended to provide a descriptive
    <EuiCode>aria-label</EuiCode>
    for each set of breadcrumbs.
  </:title>
</EuiCallOut>

# Basic

```hbs template
<EuiPageContent role={{null}}>
  <EuiBreadcrumbs
    @breadcrumbs={{this.breadcrumbs}}
    @truncate={{false}}
    aria-label='An example of EuiBreadcrumbs'
  />
  <EuiSpacer @size='xs' />
  <EuiPageHeader>
    <:pageTitle>
      Boa constrictor
    </:pageTitle>
    <:rightSideItems as |Item|>
      <Item>
        <EuiButton>Cancel</EuiButton>
      </Item>
    </:rightSideItems>
  </EuiPageHeader>
</EuiPageContent>
```

```js component
import Component from '@glimmer/component';

export default class DemoSideNavComponent extends Component {
  breadcrumbs = [
    {
      text: 'Animals',
      href: '#',
      onClick: (e) => {
        e.preventDefault();
      },
      'data-test-subj': 'breadcrumbsAnimals'
    },
    {
      text: 'Reptiles'
    },
    {
      text: 'Boa constrictor',
      href: '#',
      onClick: (e) => {
        e.preventDefault();
      }
    },
    {
      text: 'Edit',
      href: '#',
      onClick: (e) => {
        e.preventDefault();
      }
    }
  ];
}
```
