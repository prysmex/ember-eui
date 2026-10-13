---
order: 2
---

# Searching on enter key

<EuiText>

Use the `@onSearch` action to receive `EuiFieldSearch`'s current value when a user triggers a search via the <kbd>Enter</kbd> key.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiFieldSearch,
  EuiFormRow,
  EuiSpacer,
} from '@ember-eui/core/components';

export default class SearchOnEnterDemo extends Component {
  @tracked searchValue = '';

  @action
  onSearch(value) {
    this.searchValue = value;
  }

  <template>
    <EuiFormRow
      @label="Search widgets"
      @helpText="Type any text and press the enter key to trigger a search."
    >
      <EuiFieldSearch
        placeholder="Widget 22A"
        @onSearch={{this.onSearch}}
        @isClearable={{true}}
      />
    </EuiFormRow>
    <EuiSpacer />
    {{#if this.searchValue}}
      You searched for: <strong>{{this.searchValue}}</strong>
    {{/if}}
  </template>
}
```
