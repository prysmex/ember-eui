---
order: 2
---

# External links

<EuiText>
	<p>
		Setting <EuiCode>@target="_blank"</EuiCode> defaults to <code>@external=\{{true}}</code>. This adds an icon indicator instructing users that a new window will open. You can also manually apply this icon in case you handle the target behavior by other means.
  </p>

</EuiText>



```gjs component
import Component from '@glimmer/component';
import { EuiCode, EuiLink, EuiText } from '@ember-eui/core/components';

export default class DemoComponent extends Component {

  <template>
    <EuiText>
      <p>
        Open the
        <EuiLink @href='http://www.elastic.co' @target='_blank'>
          Elastic website
        </EuiLink>
        in a new tab.
      </p>
      <p>
        This
        <EuiLink @href='#/navigation/link' @external={{true}}>
          link
        </EuiLink>
        has the
        <EuiCode>@external</EuiCode>
        argument set to true.
      </p>
    </EuiText>
  </template>
}
```
