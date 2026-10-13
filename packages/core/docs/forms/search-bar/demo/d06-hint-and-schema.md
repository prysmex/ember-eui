---
order: 6
---

# Schema and hint block (Ember EUI extra)

<EuiText>

A strict `schema` validates fields and value types (`age:abc` is an
error shown in a tooltip); the hint below the field explains the syntax.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiSearchBar, EuiText, EuiSpacer } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

export default class SearchBarSchemaDemo extends Component {
  @tracked message = 'Type a query and press Enter.';

  box = {
    placeholder: 'age>30 status:active',
    schema: {
      strict: true,
      flags: ['admin'],
      fields: { age: { type: 'number' }, status: { type: 'string' } },
    },
  };

  filters = [
    {
      type: 'field_value_toggle_group',
      field: 'status',
      items: [
        { value: 'active', name: 'Active' },
        { value: 'inactive', name: 'Inactive' },
      ],
    },
  ];

  @action
  onChange({ queryText, error }) {
    this.message = error ? `Invalid: ${error.message}` : `Valid query: ${queryText || '(empty)'}`;
  }

  <template>
    <EuiSearchBar
      @box={{this.box}}
      @hint={{hash}}
      @filters={{this.filters}}
      @compressed={{true}}
      @onChange={{this.onChange}}
    >
      <:hint>
        <EuiText @size="s">Try <code>age&gt;30</code>, <code>status:active</code> or <code>is:admin</code>.</EuiText>
      </:hint>
    </EuiSearchBar>
    <EuiSpacer @size="s" />
    <EuiText @size="s" @color="subdued"><p>{{this.message}}</p></EuiText>
  </template>
}
```
