---
order: 1
---

# Basic

<EuiText>
	<p>
		<strong>EuiLink</strong> is any anchor or button element that is designed to display nicely within a block of text. It also provides more anchor-specific styling onto links and makes sure they are accessible.
  </p>

</EuiText>

```hbs template
<EuiText>
  <p>
    A simple
    <EuiLink @href='#'>EuiLink</EuiLink>
    used within a paragraph of text.
  </p>
  <p>
    This is actually a
    <EuiLink @onClick={{(noop)}}>button</EuiLink>
    with an onClick handler.
  </p>
  <p>
    Here is an example of a
    <EuiLink @href='https://google.com' @onClick={{(noop)}}>
      link
    </EuiLink>
    with both an
    <EuiCode>href</EuiCode>
    and an
    <EuiCode>onClick</EuiCode>
    handler.
  </p>
</EuiText>
```

```js component
import Component from '@glimmer/component';

export default class DemoSideNavComponent extends Component {}
```
