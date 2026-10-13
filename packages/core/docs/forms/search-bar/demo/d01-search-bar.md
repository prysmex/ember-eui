---
order: 1
---

# Search bar

<EuiText>

`EuiSearchBar` usage is specific to [Elasticsearch's Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html) (domain specific language). For more generic search use cases, consider using the basic `EuiFieldSearch` component.

An `EuiSearchBar` is a toolbar that enables the user to create/define a search query. This can be done either by entering the query syntax in a search box or by clicking any of the configured filters. The query language is not meant to be full blown search language for arbitrary data (e.g. as required in the Discover App in Kibana), yet it does provide some useful features:

- Search `terms` - one can simply type search terms (free text words) - Example, `website -production`. In this example the intention is to find all items that have the "website" terms in them but do not have the word "production". Terms are AND'd together by default.
- Phrases can be matched by surrounding multiple words with quotes - Example, `"website url"`.
- Field/value search - one can search for terms within specific fields - Example, `tag:bug -severity:high`. In this example the intention is to find all items that have "bug" in their `tag` field but do not have "high" in their `severity` field. It is also possible to define range queries on numeric and date fields. For example, `followers>=10` will only match items that have 10 followers or above. And `created>'12 Jan 2018'` will only match items that were created after 12th January 2018.
- `is` clauses - a simple boolean filter over a flag - Example, `is:open -is:assigned`. In this example the intention is to find all items that are flagged as `open` but are not flagged as `assigned`
- `or group` clauses - allowing multiple clauses to be OR'd together - Example, `(is:active OR owner:dewey) followers>5`. In this example the intention is to find all items that are `active` OR owned by `dewey`, and have more than 5 `followers`
- Operators for partial text match `:`, exact text match `=`, greater than `>`, greater than or equal `>=`, less than `<`, and less than or equal `<=`.

While the user can use the syntax described above to enter queries in the search box, it is possible to provide the user help with the syntax using filters. The filters are UI controls that can manipulate the query. The available filters are:

- `field_value_selection` - A filter to manipulate field/value clauses. The filter is associated with a field name, and provides the user a list of value options to choose from. This filter can be configured to be single or multi select. In a single select mode, only one field filter will be added and replaced when the user changes the selection. In multi-select mode, a new filter will be added for each value selection. It is the intention for all these field clauses to be ANDed.
- `field_value_toggle` - A filter to manipulate a single field/value clause. The filter is associated with a field name and a value. When the user clicks the control (button) the field/value filter is added/removed to/from the query.
- `field_value_toggle_group` - Similar to the `field_value_toggle` above, except here you can define multiple values that will be displayed as a group of toggle buttons.
- `is` - A toggle button that is associated with a flag name and when clicked it toggles this flag back and forth (adds/removed an `is:` clause to/from the query).

### Date parsing

Date values can be used for equality or range tests when the `schema` specifies the field as a `date` type (the `created` field in the demo below is a date), and must be enclosed in single quotes. E.g. `created:'2019-01-01'`, `created>='3rd January 2017'`.

Formats understood by the parser:

- relative: `yesterday`, `today`, `tomorrow`
- absolute (parsed by Moment.js's `utc` method): `ddd`, `dddd`, `D MMM YY`, `Do MMM YY`, `D MMM YYYY`, `Do MMM YYYY`, `DD MMM YY`, `DD MMM YYYY`, `D MMMM YY`, `Do MMMM YY`, `D MMMM YYYY`, `Do MMMM YYYY`, `DD MMMM YY`, `DD MMMM YYYY`, `YYYY-MM-DD`

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { htmlSafe } from '@ember/template';
import { EuiBasicTable, EuiCallOut, EuiCodeBlock, EuiFlexGroup, EuiFlexItem, EuiSearchBar, EuiSpacer, EuiSwitch, EuiTitle } from '@ember-eui/core/components';
import { Query } from '@ember-eui/core/components/eui-search-bar';

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

export default class SearchBarDemo extends Component {
  @tracked query = Query.MATCH_ALL;
  @tracked error = null;
  @tracked incremental = false;
  @tracked showHint = false;

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
      type: 'field_value_toggle',
      name: 'Popular',
      field: 'followers',
      value: 5,
      operator: 'gt',
    },
    {
      type: 'field_value_selection',
      field: 'tag',
      name: 'Tag',
      multiSelect: 'or',
      operator: 'exact',
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

  get hint() {
    return this.showHint
      ? { content: 'Type search terms, e.g. visualization or -dashboard' }
      : undefined;
  }

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
  toggleIncremental() {
    this.incremental = !this.incremental;
  }

  @action
  toggleHint() {
    this.showHint = !this.showHint;
  }

  get queriedItems() {
    return Query.execute(this.query, items, {
      defaultFields: ['owner', 'tag', 'type'],
    });
  }

  get esQueryDsl() {
    try {
      return JSON.stringify(Query.toESQuery(this.query), null, 2);
    } catch (e) {
      return String(e);
    }
  }

  get esQueryString() {
    try {
      return Query.toESQueryString(this.query);
    } catch (e) {
      return String(e);
    }
  }

  items = items;
  columns = columns;
  schema = schema;

  <template>
    <EuiSearchBar
      @box={{this.box}}
      @filters={{this.filters}}
      @hint={{this.hint}}
      @onChange={{this.onChange}}
    />
    <EuiSpacer @size="s" />
    <EuiFlexGroup @justifyContent="flexEnd">
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Incremental"
          @checked={{this.incremental}}
          @onChange={{this.toggleIncremental}}
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label="Show hint"
          @checked={{this.showHint}}
          @onChange={{this.toggleHint}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size="l" />
    {{#if this.error}}
      <EuiCallOut
        @iconType="faceSad"
        @color="danger"
        @title={{this.errorTitle}}
      />
      <EuiSpacer @size="l" />
    {{else}}
      <EuiFlexGroup @wrap={{true}}>
        <EuiFlexItem>
          <EuiTitle @size="s"><h3>Elasticsearch Query String</h3></EuiTitle>
          <EuiSpacer @size="s" />
          <EuiCodeBlock @language="js">{{this.esQueryString}}</EuiCodeBlock>
        </EuiFlexItem>
        <EuiFlexItem>
          <EuiTitle @size="s"><h3>Elasticsearch Query DSL</h3></EuiTitle>
          <EuiSpacer @size="s" />
          <EuiCodeBlock @language="js">{{this.esQueryDsl}}</EuiCodeBlock>
        </EuiFlexItem>
        <EuiFlexItem style="flex-basis: 100%">
          <EuiTitle @size="s"><h3>JS execution</h3></EuiTitle>
          <EuiSpacer @size="s" />
          <EuiBasicTable
            @tableCaption="Items matching the query"
            @items={{this.queriedItems}}
            @columns={{this.columns}}
          />
        </EuiFlexItem>
      </EuiFlexGroup>
    {{/if}}
  </template>
}
```
