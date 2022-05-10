---
order: 6
---

# Color for emphasis

<EuiText>
	<p>
		Alternatively, you can change number of breadcrumbs that show per breakpoint by passing a custom responsive object.
  </p>

</EuiText>

```hbs template
<EuiBreadcrumbs
  @breadcrumbs={{this.breadcrumbs}}
  @responsive={{hash xs=1 s=3 m=5 xl=6}}
	@max={{null}}
  aria-label='An example of custom responsive EuiBreadcrumbs'
/>
```

```js component
import Component from '@glimmer/component';

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
}
```
