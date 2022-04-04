---
order: 5
---

# Responsive

<EuiText>
	<p>
		<strong>EuiBreadcrumbs</strong> are <EuiCode>responsive</EuiCode> by default and will collapse breadcrumbs on narrower screens. Setting <EuiCode @language="json">responsive={false}</EuiCode> will keep all breadcrumbs visible at all screens sizes.
  </p>

</EuiText>

```hbs template
<EuiBreadcrumbs
  @breadcrumbs={{this.breadcrumbs}}
  @max={{null}}
  @responsive={{false}}
  aria-label='An example of non-responsive EuiBreadcrumbs'
/>
```

```js component
import Component from '@glimmer/component';

export default class DemoSideNavComponent extends Component {
  breadcrumbs = [
    {
      text: 'Animals',
      href: '#'
    },
    {
      text: 'Metazoans',
      href: '#'
    },
    {
      text: 'Chordates',
      href: '#'
    },
    {
      text: 'Vertebrates',
      href: '#'
    },
    {
      text: 'Tetrapods',
      href: '#'
    },
    {
      text: 'Reptiles',
      href: '#'
    },
    {
      text: 'Boa constrictor',
      href: '#'
    },
    {
      text: 'Nebulosa subspecies'
    }
  ];
}
```
