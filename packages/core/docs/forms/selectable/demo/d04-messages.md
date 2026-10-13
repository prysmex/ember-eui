---
order: 4
---

# Loading and empty

<EuiText>

`@isLoading` shows a spinner and "Loading options"; with no options,
`@emptyMessage` (or "No options available"); a search matching nothing
says so.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiFlexGroup, EuiFlexItem, EuiSelectable } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

export default class SelectableMessages extends Component {
  none = [];

  <template>
    <EuiFlexGroup>
      <EuiFlexItem>
        <EuiSelectable
          @options={{this.none}}
          @isLoading={{true}}
          @listProps={{hash bordered=true}}
          aria-label="Loading example"
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiSelectable
          @options={{this.none}}
          @emptyMessage="You have no saved searches yet"
          @listProps={{hash bordered=true}}
          aria-label="Empty example"
        />
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```
