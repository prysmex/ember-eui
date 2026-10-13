---
order: 1
---

# Breadcrumbs

<EuiText>

**EuiBreadcrumbs** let the user track their progress within and back out of a UX flow and work well when used in combination with **EuiPageHeader**. They are meant to be used at lower page level flows, while **EuiHeaderBreadcrumbs** should be used for application-wide navigation.

**EuiBreadcrumbs** requires an array of breadcrumb objects as `@breadcrumbs` and handles truncation, including middle-truncation in the case of many items, and mobile responsiveness. Each item accepts an `href`, though we recommend the last item represent the current page and therefore the link is unnecessary.

Provide a descriptive `aria-label` for each set of breadcrumbs.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiBreadcrumbs, EuiButton, EuiPageHeader, EuiPanel, EuiSpacer } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
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

  <template>
    <EuiPanel>
      <EuiBreadcrumbs
        @breadcrumbs={{this.breadcrumbs}}
        @truncate={{false}}
        aria-label='An example of EuiBreadcrumbs'
      />
      <EuiSpacer @size='xs' />
      <EuiPageHeader role="">
        <:pageTitle>
          Boa constrictor
        </:pageTitle>
        <:rightSideItems as |Item|>
          <Item>
            <EuiButton>Cancel</EuiButton>
          </Item>
        </:rightSideItems>
      </EuiPageHeader>
    </EuiPanel>
  </template>
}
```
