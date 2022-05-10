---
order: 2
---

# Limit the number of breadcrumbs

<EuiText>
	<p>
		Use the <EuiCode>max</EuiCode> prop to collapse breadcrumbs beyond a certain number. The center breadcrumbs will collpase into a single item allowing the user to navigate these items from within a popover.
  </p>

</EuiText>

```hbs template
<EuiBreadcrumbs
  @max={{4}}
  @breadcrumbs={{this.breadcrumbs}}
  @truncate={{false}}
  aria-label='An example of EuiBreadcrumbs with specifying max prop'
/>
```

```js component
import Component from '@glimmer/component';

export default class DemoSideNavComponent extends Component {
  breadcrumbs = [
    {
      text: 'Animals',
      href: '#',
    },
    {
      text: 'Metazoans',
      href: '#',
    },
    {
      text: 'Chordates',
      href: '#',
    },
    {
      text: 'Vertebrates',
      href: '#',
    },
    {
      text: 'Tetrapods',
      href: '#',
    },
    {
      text: 'Reptiles',
      href: '#',
    },
    {
      text: 'Boa constrictor',
      href: '#',
    },
    {
      text: 'Nebulosa subspecies',
    },
  ];
}
```
