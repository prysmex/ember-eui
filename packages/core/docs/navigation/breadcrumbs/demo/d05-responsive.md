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

<EuiText>
	<p>
		Alternatively, you can change number of breadcrumbs that show per breakpoint by passing a custom responsive object.
  </p>
</EuiText>


<EuiBreadcrumbs
  @breadcrumbs={{this.breadcrumbs}}
  @responsive={{hash xs=1 s=3 m=5 xl=6}}
	@max={{null}}
  aria-label='An example of custom responsive EuiBreadcrumbs'
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
