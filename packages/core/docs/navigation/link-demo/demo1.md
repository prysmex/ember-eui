---
order: 1
---

# Link

<EuiText>

**EuiLink** is any anchor or button element that is designed to display nicely within a block of text. It also provides more anchor-specific styling onto links and makes sure they are accessible.

</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { EuiCode, EuiLink, EuiText } from '@ember-eui/core/components';

export default class DemoComponent extends Component {
  @action
  noop(event) {
    // keep the demo page where it is
    event.preventDefault();
  }

  <template>
    <EuiText>
      <p>
        A simple
        <EuiLink @href='#/navigation/link'>EuiLink</EuiLink>
        used within a paragraph of text.
      </p>
      <p>
        This is actually a
        <EuiLink {{on 'click' this.noop}}>button</EuiLink>
        with a click handler.
      </p>
      <p>
        Here is an example of a
        <EuiLink @href='https://github.com/elastic/eui' {{on 'click' this.noop}}>
          link
        </EuiLink>
        with both an
        <EuiCode>@href</EuiCode>
        and a
        <EuiCode>\{{on "click"}}</EuiCode>
        handler.
      </p>
    </EuiText>
  </template>
}
```
