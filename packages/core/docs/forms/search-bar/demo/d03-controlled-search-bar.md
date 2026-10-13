---
order: 3
---

# Controlled search bar

<EuiText>

An `EuiSearchBar` can have its query controlled by a parent component by passing `@query`. Changes to the query will be passed back up through the `@onChange` action where the new query must be stored in state and passed back into the search bar.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { htmlSafe } from '@ember/template';
import { EuiBasicTable, EuiButton, EuiCallOut, EuiFlexGroup, EuiFlexItem, EuiSearchBar, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';
import { Query } from '@ember-eui/core/components/eui-search-bar';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

const tags = [
  { name: 'marketing', color: 'danger' },
  { name: 'finance', color: 'success' },
  { name: 'eng', color: 'success' },
  { name: 'sales', color: 'warning' },
  { name: 'ga', color: 'success' },
];

const items = [
  { id: 0, status: 'open', type: 'dashboard', tag: ['marketing', 'sales'], active: true, owner: 'dewey', followers: 12, comments: 3, stars: 4 },
  { id: 1, status: 'closed', type: 'visualization', tag: ['finance'], active: false, owner: 'wanda', followers: 2, comments: 0, stars: 1 },
  { id: 2, status: 'open', type: 'watch', tag: ['eng', 'ga', 'sales'], active: true, owner: 'carrie', followers: 8, comments: 7, stars: 5 },
  { id: 3, status: 'open', type: 'visualization', tag: [], active: true, owner: 'jmack', followers: 20, comments: 10, stars: 3 },
  { id: 4, status: 'closed', type: 'dashboard', tag: ['ga'], active: false, owner: 'gabic', followers: 5, comments: 2, stars: 2 },
  { id: 5, status: 'closed', type: 'watch', tag: ['marketing'], active: true, owner: 'dewey', followers: 0, comments: 1, stars: 0 },
  { id: 6, status: 'open', type: 'dashboard', tag: ['eng'], active: false, owner: 'wanda', followers: 15, comments: 4, stars: 5 },
  { id: 7, status: 'open', type: 'visualization', tag: ['finance', 'sales'], active: true, owner: 'dewey', followers: 6, comments: 9, stars: 2 },
  { id: 8, status: 'closed', type: 'watch', tag: ['ga', 'eng'], active: true, owner: 'carrie', followers: 3, comments: 5, stars: 4 },
  { id: 9, status: 'open', type: 'dashboard', tag: ['marketing', 'finance', 'ga'], active: false, owner: 'jmack', followers: 18, comments: 6, stars: 1 },
];

const loadTags = () =>
  new Promise((resolve) => {
    setTimeout(() => {
      resolve(tags.map((tag) => ({ value: tag.name })));
    }, 2000);
  });

const schema = {
  strict: true,
  fields: {
    type: { type: 'string' },
    active: { type: 'boolean' },
    status: { type: 'string' },
    followers: { type: 'number' },
    comments: { type: 'number' },
    stars: { type: 'number' },
    created: { type: 'date' },
    owner: { type: 'string' },
    tag: {
      type: 'string',
      validate: (value) => {
        if (value !== '' && !tags.some((tag) => tag.name === value)) {
          throw new Error(
            `unknown tag (possible values: ${tags.map((tag) => tag.name).join(',')})`
          );
        }
      },
    },
  },
};

const columns = [
  { name: 'Type', field: 'type' },
  {
    name: 'Open',
    field: 'status',
    render: (status) => (status === 'open' ? 'Yes' : 'No'),
  },
  { name: 'Active', field: 'active', dataType: 'boolean' },
  { name: 'Tags', field: 'tag', render: (tag) => (tag ?? []).join(', ') },
  { name: 'Owner', field: 'owner' },
  {
    name: 'Stats',
    width: '150px',
    render: (item) =>
      htmlSafe(
        `<div><div>${item.stars} Stars</div><div>${item.followers} Followers</div><div>${item.comments} Comments</div></div>`
      ),
  },
];

export default class SearchBarControlledDemo extends Component {
  @tracked query = 'status:open';
  @tracked error = null;
  @tracked incremental = false;

  filters = [
    {
      type: 'field_value_toggle_group',
      field: 'status',
      items: [
        { value: 'open', name: 'Open' },
        { value: 'closed', name: 'Closed' },
      ],
    },
    {
      type: 'is',
      field: 'active',
      name: 'Active',
      negatedName: 'Inactive',
    },
    {
      type: 'field_value_toggle',
      name: 'Mine',
      field: 'owner',
      value: 'dewey',
    },
    {
      type: 'field_value_selection',
      field: 'tag',
      name: 'Tag',
      multiSelect: 'or',
      cache: 10000, // will cache the loaded tags for 10 sec
      options: () => loadTags(),
    },
  ];

  get box() {
    return {
      placeholder: 'type:visualization -is:active joe',
      incremental: this.incremental,
      schema,
    };
  }

  get errorTitle() {
    return `Invalid search: ${this.error?.message}`;
  }

  get queriedItems() {
    return Query.execute(this.query, items, {
      defaultFields: ['owner', 'tag', 'type'],
    });
  }

  columns = columns;

  @action
  onChange({ query, error }) {
    if (error) {
      this.error = error;
    } else {
      this.error = null;
      this.query = query;
    }
  }

  @action
  setQuery(query) {
    this.query = query;
  }

  @action
  toggleIncremental() {
    this.incremental = !this.incremental;
  }

  <template>
    <p>Enter a query, or select one from a bookmark</p>
    <EuiSpacer @size="s" />
    <EuiFlexGroup>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" (fn this.setQuery "status:open owner:dewey")}}>
          mine, open
        </EuiButton>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiButton @size="s" {{on "click" (fn this.setQuery "status:closed owner:dewey")}}>
          mine, closed
        </EuiButton>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size="m" />
    <EuiFlexGroup @alignItems="center">
      <EuiFlexItem>
        <EuiSearchBar
          @query={{this.query}}
          @box={{this.box}}
          @filters={{this.filters}}
          @onChange={{this.onChange}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Incremental"
          @checked={{this.incremental}}
          @onChange={{this.toggleIncremental}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size="l" />
    {{#if this.error}}
      <EuiCallOut @iconType="faceSad" @color="danger" @title={{this.errorTitle}} />
      <EuiSpacer @size="l" />
    {{else}}
      <EuiBasicTable
        @tableCaption="Items matching the query"
        @items={{this.queriedItems}}
        @columns={{this.columns}}
      />
    {{/if}}
  </template>
}
```
