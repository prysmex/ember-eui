---
order: 4
---

# Disabled links

<EuiText>
	<p>
		When an <strong>EuiLink</strong> is given a click handler (<EuiCode>\{{on "click"}}</EuiCode>), and is not passed an <EuiCode>@href</EuiCode>, it can optionally be set to <EuiCode>@disabled</EuiCode> which disables the click behavior, and removes the link styling.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiHorizontalRule, EuiLink, EuiSwitch, EuiText, EuiTextColor } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @tracked disableLink = true;

  @action
  toggle() {
    this.disableLink = !this.disableLink;
  }

  @action
  noop() {}

  <template>
    <EuiText>
      <EuiSwitch
        @compressed={{true}}
        @label='Disable links'
        @checked={{this.disableLink}}
        @onChange={{this.toggle}}
      />
      <EuiHorizontalRule @margin='m' />
      <p>
        This
        <EuiLink @color='accent' @disabled={{this.disableLink}} {{on 'click' this.noop}}>
          paragraph
        </EuiLink>
        has two
        {{if this.disableLink ' disabled ' ' enabled '}}
        <EuiLink @color='warning' @disabled={{this.disableLink}} {{on 'click' this.noop}}>
          links
        </EuiLink>
        in it.
      </p>
      <p>
        <EuiTextColor @color='accent'>
          When links are disabled, they inherit the
          <EuiLink @color='success' @disabled={{this.disableLink}} {{on 'click' this.noop}}>
            color
          </EuiLink>
          of surrounding text.
        </EuiTextColor>
      </p>
    </EuiText>
  </template>
}
```
