---
order: 1
---

# Breadcrumbs

<EuiText>

Links (`href`), actions (`onClick`) and the current page, which is
marked with `aria-current="page"`.

</EuiText>

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
