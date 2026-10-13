---
order: 5
---

# Link validation

<EuiText>
	<p>
		To make links more secure for users, <strong>EuiLink</strong> and other components that accept an <EuiCode>@href</EuiCode> argument become disabled if that <EuiCode>href</EuiCode> uses the <EuiCode>javascript:</EuiCode> protocol. This helps protect consuming applications from cross-site scripting (XSS) attacks.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiLink, EuiText } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  urls = [
    'https://elastic.co',
    '//elastic.co',
    'relative/url/somewhere',
    'http://username:password@example.com/',
    'javascript:alert()'
  ];

  <template>
    <EuiText>
      {{#each this.urls as |url|}}
        <p>
          <EuiLink @color='success' @href={{url}}>
            {{url}}
          </EuiLink>
        </p>
      {{/each}}
    </EuiText>
  </template>
}
```
