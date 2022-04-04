---
order: 1
---

# Coloring links

<EuiText>
	<p>
		Like any other <EuiLink @href="/docs/core/docs/navigation/button">button component</EuiLink>, links can be passed a <EuiCode>color</EuiCode>. Note that the <EuiCode>ghost</EuiCode> type should only be used on dark backgrounds (regardless of theming) as it will always create a white link.
  </p>
</EuiText>

```hbs template
<EuiText>
  <ul>
    {{#each this.links as |value|}}
      <li>
        <EuiLink @color={{if (not-eq value 'disabled') value}} @href='#'>
          {{value}}
        </EuiLink>
      </li>

    {{/each}}
    <li style="background-color: black">
      <EuiLink @color='ghost'>Ghost</EuiLink>
    </li>
  </ul>
</EuiText>
```

```js component
import Component from '@glimmer/component';

export default class DemoSideNavComponent extends Component {
  links = [
    'primary',
    'subdued',
    'success',
    'accent',
    'warning',
    'danger',
    'text'
  ];
}
```
