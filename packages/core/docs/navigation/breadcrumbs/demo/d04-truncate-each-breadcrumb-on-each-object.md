---
order: 4
---

# Truncate each breadcrumb on each object

<EuiText>
	<p>
		Alternatively, you can force truncation on single breadcrumb <strong>item</strong> by adding <EuiCode @language="json">truncate: true</EuiCode> to the object.
  </p>

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiBreadcrumbs } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
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

  <template>
    <EuiBreadcrumbs
      @breadcrumbs={{this.breadcrumbs}}
      @truncate={{false}}
      aria-label='An example of EuiBreadcrumbs without truncate prop'
    />
  </template>
}
```
