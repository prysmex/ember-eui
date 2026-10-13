---
order: 3
---

# Incremental search

<EuiText>

To search as the user types into the field, set `@incremental={{true}}`.

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

export default class IncrementalSearchFormsDemo extends Component {
  @tracked searchValue = '';

  @action
  onSearch(value) {
    this.searchValue = value;
  }

  <template>
    <EuiFormRow
      @label="Search forms"
      @helpText="Type any text to begin searching."
    >
      <EuiFieldSearch
        placeholder="Form 413B"
        @onSearch={{this.onSearch}}
        @incremental={{true}}
        @isClearable={{true}}
      />
    </EuiFormRow>
    <EuiSpacer />
    {{#if this.searchValue}}
      Searching for: <strong>{{this.searchValue}}</strong>
    {{/if}}
  </template>
}
```
