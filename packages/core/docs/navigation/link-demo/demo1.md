---
order: 1
---

# Link

<EuiText>

A link with `@href`, and a link-styled button without it.

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
    <EuiLink>button</EuiLink>
    with an onClick handler.
  </p>
  <p>
    Here is an example of a
    <EuiLink @href='https://google.com'>
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
