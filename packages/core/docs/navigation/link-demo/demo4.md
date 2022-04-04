---
order: 4
---

# Disabled links

<EuiText>
	<p>
		When an <strong>EuiLink</strong> is passed an <EuiCode>onClick</EuiCode> method, and is not passed an <EuiCode>href</EuiCode>, it can optionally be set to <EuiCode>disabled</EuiCode> which disables the click behavior, and removes the link styling.
  </p>
</EuiText>

```hbs template
<EuiText>
  <EuiSwitch
    @compressed={{true}}
    @label='Disable links'
    @checked={{this.disableLink}}
    @onChange={{set this 'disableLink' (not this.disableLink)}}
  />
  <EuiHorizontalRule margin='m' />
  <p>
    This
    <EuiLink @color='accent' @disabled={{this.disableLink}} @onClick={{(noop)}}>
      paragraph
    </EuiLink>
    has two
    {{if this.disableLink ' disabled ' ' enabled '}}
    <EuiLink
      @color='warning'
      @disabled={{this.disableLink}}
      @onClick={{(noop)}}
    >
      links
    </EuiLink>
    in it.
  </p>
  <p>
    <EuiTextColor @color='accent'>
      When links are disabled, they inherit the
      <EuiLink
        @color='success'
        @disabled={{this.disableLink}}
        @onClick={{(noop)}}
      >
        color
      </EuiLink>
      of surrounding text.
    </EuiTextColor>
  </p>
</EuiText>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class DemoSideNavComponent extends Component {
  @tracked disableLink = false;
}
```
