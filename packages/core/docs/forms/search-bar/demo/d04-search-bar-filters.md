---
order: 4
---

# Search bar filters

<EuiText>

An `EuiSearchBar` can have custom filter dropdowns that control how a user can search. The `field_value_selection` filter's `filterWith` is `'prefix'` (default), `'includes'` or your own function, and `autoSortOptions={{false}}` keeps your option order. A `custom_component` filter is an Ember component receiving `@query` and `@onChange`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { htmlSafe } from '@ember/template';
import { EuiBasicTable, EuiButton, EuiCallOut, EuiCodeBlock, EuiFilterButton, EuiFlexGroup, EuiFlexItem, EuiPanel, EuiPopover, EuiSearchBar, EuiSpacer, EuiTitle } from '@ember-eui/core/components';
import { Query } from '@ember-eui/core/components/eui-search-bar';
import { on } from '@ember/modifier';
import { not } from 'ember-truth-helpers';

const tags = [
  { name: 'marketing', color: 'danger' },
  { name: 'finance', color: 'success' },
  { name: 'eng', color: 'success' },
  { name: 'sales', color: 'warning' },
  { name: 'ga', color: 'success' },
  { name: 'pre-sales', color: 'success' },
  { name: 'product', color: 'warning' },
  { name: 'engineering', color: 'success' },
  { name: 'design', color: 'warning' },
  { name: 'early-birds', color: 'success' },
  { name: 'people-ops', color: 'danger' },
  { name: 'solutions', color: 'success' },
  { name: 'elasticsearch', color: 'success' },
  { name: 'kibana', color: 'success' },
  { name: 'cloud', color: 'danger' },
  { name: 'logstash', color: 'warning' },
  { name: 'beats', color: 'warning' },
  { name: 'legal', color: 'danger' },
  { name: 'revenue', color: 'success' },
  { name: 'public-relations', color: 'success' },
  { name: 'social-media-management', color: 'warning' },
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

const TAG_OPTIONS = tags.map((tag) => ({ value: tag.name }));

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

class CustomFilter extends Component {
  @tracked isOpen = false;

  get orTagsClause() {
    return this.args.query.getOrFieldClause('tag');
  }

  get selectedTags() {
    return this.orTagsClause?.value ?? [];
  }

  get hasCloudExcluded() {
    const simpleTagClause = this.args.query.getSimpleFieldClause('tag');

    return Boolean(
      simpleTagClause &&
        simpleTagClause.match === 'must_not' &&
        simpleTagClause.operator === 'eq'
    );
  }

  get isOnlySales() {
    return (
      this.selectedTags.length === 1 &&
      this.selectedTags[0] === 'sales' &&
      !this.hasCloudExcluded
    );
  }

  get numActiveFilters() {
    return this.isOnlySales ? 1 : undefined;
  }

  get hasFiltersApplied() {
    return this.args.query.hasClauses();
  }

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  closePopover() {
    this.isOpen = false;
  }

  @action
  onlySales() {
    this.args.onChange(
      this.args.query
        .removeSimpleFieldValue('tag', 'cloud')
        .removeOrFieldClauses('tag')
        .addOrFieldValue('tag', 'sales', true, 'eq')
    );
    this.closePopover();
  }

  @action
  excludeCloud() {
    this.args.onChange(
      this.args.query.addSimpleFieldValue('tag', 'cloud', false, 'eq')
    );
    this.closePopover();
  }

  @action
  removeAll() {
    this.args.onChange(this.args.query.removeAllClauses());
    this.closePopover();
  }

  <template>
    <EuiPopover
      @isOpen={{this.isOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize="none"
      @anchorPosition="downCenter"
    >
      <:button>
        <EuiFilterButton
          @iconType="chevronSingleDown"
          @iconSide="right"
          @hasActiveFilters={{this.isOnlySales}}
          @numActiveFilters={{this.numActiveFilters}}
          @grow={{true}}
          {{on "click" this.toggle}}
        >
          Custom
        </EuiFilterButton>
      </:button>
      <:content>
        <EuiPanel @paddingSize="m">
          <EuiFlexGroup>
            <EuiFlexItem>
              <EuiButton @disabled={{this.isOnlySales}} {{on "click" this.onlySales}}>
                Only sales
              </EuiButton>
            </EuiFlexItem>
            <EuiFlexItem>
              <EuiButton @disabled={{this.hasCloudExcluded}} {{on "click" this.excludeCloud}}>
                Exclude cloud
              </EuiButton>
            </EuiFlexItem>
            <EuiFlexItem>
              <EuiButton @disabled={{not this.hasFiltersApplied}} {{on "click" this.removeAll}}>
                All
              </EuiButton>
            </EuiFlexItem>
          </EuiFlexGroup>
        </EuiPanel>
      </:content>
    </EuiPopover>
  </template>
}

export default class SearchBarFiltersDemo extends Component {
  @tracked query = Query.MATCH_ALL;
  @tracked error = null;

  columns = columns;
  box = { placeholder: 'type:visualization -is:active joe', incremental: true, schema };

  filters = [
    {
      type: 'field_value_selection',
      field: 'tag',
      name: 'Tag ("prefix" filter, default)',
      multiSelect: 'or',
      options: TAG_OPTIONS,
    },
    {
      type: 'field_value_selection',
      field: 'tag',
      name: 'Tag ("includes" filter)',
      filterWith: 'includes',
      multiSelect: 'or',
      options: TAG_OPTIONS,
    },
    {
      type: 'field_value_selection',
      field: 'tag',
      name: 'Tag (custom filter)',
      filterWith: () => Math.random() > 0.5,
      multiSelect: 'or',
      options: TAG_OPTIONS,
      autoSortOptions: false,
    },
    {
      type: 'custom_component',
      component: CustomFilter,
    },
  ];

  get errorTitle() {
    return `Invalid search: ${this.error?.message}`;
  }

  get queriedItems() {
    return Query.execute(this.query, items, {
      defaultFields: ['owner', 'tag', 'type'],
    });
  }

  get esQueryDsl() {
    return JSON.stringify(Query.toESQuery(this.query), null, 2);
  }

  get esQueryString() {
    return Query.toESQueryString(this.query);
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

  <template>
    <EuiSearchBar
      @box={{this.box}}
      @filters={{this.filters}}
      @onChange={{this.onChange}}
    />
    <EuiSpacer @size="l" />
    {{#if this.error}}
      <EuiCallOut @iconType="faceSad" @color="danger" @title={{this.errorTitle}} />
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
