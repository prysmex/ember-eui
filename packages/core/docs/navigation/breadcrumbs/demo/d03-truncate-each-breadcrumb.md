---
order: 3
---

# Truncate each breadcrumb

<EuiText>
	<p>
		<strong>EuiBreadcrumbs</strong> will truncate the full set by default, forcing it to a single line and setting a max width on all items except for the last. You can turn this off by setting <EuiCode @language="jsx">truncate={false}</EuiCode>.
  </p>

</EuiText>

```hbs template
<EuiBreadcrumbs
  @breadcrumbs={{this.breadcrumbs}}
  @truncate={{true}}
  aria-label='An example of EuiBreadcrumbs with truncate prop'
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
      text: 'Metazoans is a real mouthful, especially for creatures without mouths',
      href: '#',
      truncate: true
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
      text: 'Nebulosa subspecies is also a real mouthful, especially for creatures without mouths'
    }
  ];
}
```
