---
order: 5
---

# People list with a reset button (Ember EUI extra)

<EuiText>

Type a query (for example `ann` or `-role:engineer`) or use the filters.
The matching people come from `Query.execute`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { Query } from '@ember-eui/core/components/eui-search-bar';
import { EuiSearchBar, EuiButton, EuiSpacer, EuiCallOut, EuiText } from '@ember-eui/core/components';
import { hash } from '@ember/helper';
import { on } from '@ember/modifier';

const PEOPLE = [
  { name: 'Ann', role: 'engineer', online: true },
  { name: 'Bob', role: 'designer', online: false },
  { name: 'Cid', role: 'engineer', online: false },
  { name: 'Dee', role: 'manager', online: true },
];

export default class SearchBarPeopleDemo extends Component {
  @tracked query = Query.parse('is:online');
  @tracked queryText = 'is:online';
  @tracked error = null;

  filters = [
    { type: 'is', field: 'online', name: 'Online', negatedName: 'Offline' },
    {
      type: 'field_value_selection',
      field: 'role',
      name: 'Role',
      multiSelect: 'or',
      options: [
        { value: 'engineer', name: 'Engineer' },
        { value: 'designer', name: 'Designer' },
        { value: 'manager', name: 'Manager' },
      ],
    },
  ];

  get people() {
    return Query.execute(this.query, PEOPLE);
  }

  @action
  onChange({ query, queryText, error }) {
    this.queryText = queryText;
    this.error = error ? error.message : null;
    if (query) this.query = query;
  }

  @action
  reset() {
    this.query = Query.parse('');
    this.queryText = '';
    this.error = null;
  }

  <template>
    <EuiSearchBar
      @defaultQuery="is:online"
      @box={{hash placeholder="Search people" incremental=true}}
      @filters={{this.filters}}
      @onChange={{this.onChange}}
    >
      <:toolsRight>
        <EuiButton @size="s" @iconType="refresh" {{on "click" this.reset}}>Reset</EuiButton>
      </:toolsRight>
    </EuiSearchBar>
    <EuiSpacer />
    {{#if this.error}}
      <EuiCallOut @color="danger" @iconType="warning" @title={{this.error}} />
    {{else}}
      <EuiText @size="s">
        <p><strong>Query:</strong> <code>{{this.queryText}}</code></p>
        <ul>
          {{#each this.people as |person|}}
            <li>{{person.name}} ({{person.role}}){{if person.online " · online"}}</li>
          {{else}}
            <li>Nobody matches.</li>
          {{/each}}
        </ul>
      </EuiText>
    {{/if}}
  </template>
}
```
