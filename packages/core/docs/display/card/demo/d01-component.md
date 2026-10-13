---
order: 1
---

# Component

<EuiText>

At its core an **EuiCard** should contain a `@title`, `@description`, and an `@icon`. You can make the whole card clickable by giving it an `@onClick` handler or `@href`.

For accessibility and heading hierarchy, a card's title element is a `span` by default. However, this can be changed via the `@titleElement` argument without altering the visual size.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiCard, EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';
import { concat } from '@ember/helper';
import { eq } from 'ember-truth-helpers';

export default class CardDemo extends Component {
  icons = ['Beats', 'Cloud', 'Kibana'];
  noop = () => {};

  <template>
    <EuiFlexGroup @gutterSize="l">
      {{#each this.icons as |item|}}
        <EuiFlexItem>
          <EuiCard
            @icon={{concat "logo" item}}
            @iconSize="xxl"
            @title={{concat "Elastic " item}}
            @isDisabled={{eq item "Kibana"}}
            @description="Example of a card's description. Stick to one or two sentences."
            @onClick={{this.noop}}
          />
        </EuiFlexItem>
      {{/each}}
    </EuiFlexGroup>
  </template>
}
```

