---
order: 5
---

# Responsive

<EuiText>
	<p>
		<strong>EuiBreadcrumbs</strong> are <EuiCode>@responsive</EuiCode> by default and will collapse breadcrumbs on narrower screens. Setting <code>@responsive=\{{false}}</code> will keep all breadcrumbs visible at all screens sizes.
  </p>

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { hash } from '@ember/helper';
import { EuiBreadcrumbs, EuiSpacer, EuiText } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
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

  <template>
    <EuiBreadcrumbs
      @breadcrumbs={{this.breadcrumbs}}
      @max={{null}}
      @responsive={{false}}
      aria-label='An example of non-responsive EuiBreadcrumbs'
    />

    <EuiSpacer />

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
  </template>
}
```
