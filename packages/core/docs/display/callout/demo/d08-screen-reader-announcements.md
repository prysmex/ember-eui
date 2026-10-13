---
order: 8
---

# Screen reader announcements

<EuiText>

`EuiCallOut` supports announcing its content to screen readers when it first appears using the `@announceOnMount` argument. When enabled, the callout's title and content will be announced via an `aria-live` region. The announcement will be cleared after 2 seconds to prevent duplicate DOM content but screen readers will continue reading the message even after it's cleared.

Generally you won't need this argument when a callout is rendered on initial page load, as screen readers will encounter the content during normal page navigation. Use `@announceOnMount` when the callout appears as the result of a user action or contains information that needs immediate attention.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiButton, EuiCallOut, EuiSpacer } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class CallOutAnnounceDemo extends Component {
  @tracked isShown = false;

  @action toggle() {
    this.isShown = !this.isShown;
  }

  <template>
    <EuiButton {{on "click" this.toggle}}>
      {{if this.isShown "Hide" "Show"}} callout
    </EuiButton>
    <EuiSpacer />
    {{#if this.isShown}}
      <EuiCallOut
        @title="Important notification!"
        @text="This content will be announced to screen readers when it appears."
        @announceOnMount={{true}}
      />
    {{/if}}
  </template>
}
```

