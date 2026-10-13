---
order: 3
---

# Coloring links

<EuiText>
	<p>
		Like any other <EuiLink @href="/docs/core/docs/navigation/button">button component</EuiLink>, links can be passed a <EuiCode>@color</EuiCode>. Note that the <EuiCode>ghost</EuiCode> type should only be used on dark backgrounds (regardless of theming) as it will always create a white link.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { notEq } from 'ember-truth-helpers';
import { EuiLink, EuiText } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  links = [
    'primary',
    'subdued',
    'success',
    'accent',
    'warning',
    'danger',
    'text'
  ];

  <template>
    <EuiText>
      <ul>
        {{#each this.links as |value|}}
          <li>
            <EuiLink @color={{if (notEq value 'disabled') value}} @href='#'>
              {{value}}
            </EuiLink>
          </li>

        {{/each}}
        <li style="background: black">
          <EuiLink @color='ghost'>Ghost</EuiLink>
        </li>
      </ul>
    </EuiText>
  </template>
}
```
