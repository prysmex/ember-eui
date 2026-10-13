---
order: 6
---

# Color for emphasis

<EuiText>
	<p>
		Ember EUI extension: set <EuiCode @language="json">color</EuiCode> on a breadcrumb object to emphasize it, for example <EuiCode>primary</EuiCode> or <EuiCode>danger</EuiCode>.
  </p>

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiBreadcrumbs } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  breadcrumbs = [
    {
      text: 'Animals',
      href: '#',
      color: 'primary',
      onClick: (e) => e.preventDefault(),
    },
    {
      text: 'Reptiles',
      color: 'primary',
    },
    {
      text: 'Boa constrictor', // todo support icon
      title: 'Boa constrictor has an error',
      href: '#',
      color: 'danger',
      onClick: (e) => e.preventDefault(),
    },
    {
      text: 'Edit',
    }
  ];

  <template>
    <EuiBreadcrumbs
      @breadcrumbs={{this.breadcrumbs}}
      @max={{null}}
      aria-label='An example of EuiBreadcrumbs with colors'
    />
  </template>
}
```
