---
order: 1
---

# External links

<EuiText>
	<p>
		Setting <EuiCode>target="_blank"</EuiCode> defaults to <EuiCode>external={true}</EuiCode>. This adds an icon indicator instructing users that a new window will open. You can also manually apply this icon in case you handle the target behavior by other means.
  </p>

</EuiText>



```hbs template
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
    <EuiCode>external</EuiCode>
    prop set to true.
  </p>
</EuiText>
```

```js component
import Component from '@glimmer/component';

export default class DemoSideNavComponent extends Component {}
```
