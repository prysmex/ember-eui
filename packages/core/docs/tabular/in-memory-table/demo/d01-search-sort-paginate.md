---
order: 1
---

# Search, filters, sorting and pagination

<EuiText>

Try `language:ts`, `stars>1000` or `-is:archived`. The schema comes from
the columns, so unknown fields and wrong types are errors.

</EuiText>

```hbs template
<EuiInMemoryTable
  @items={{this.repos}}
  @itemId="id"
  @columns={{this.columns}}
  @search={{this.search}}
  @sorting={{this.sorting}}
  @pagination={{this.pagination}}
  @selection={{this.selection}}
  @tableCaption="Repositories"
>
  <:childrenBetween>
    <EuiText @size="xs" @color="subdued"><p>{{this.selected.length}} repositories selected</p></EuiText>
    <EuiSpacer @size="s" />
  </:childrenBetween>
</EuiInMemoryTable>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

const LANGUAGES = ['js', 'ts', 'css', 'rust'];
const REPOS = Array.from({ length: 23 }, (_, id) => ({
  id,
  name: `project-${String(id + 1).padStart(2, '0')}`,
  language: LANGUAGES[id % LANGUAGES.length],
  stars: (id * 977) % 5000,
  archived: id % 5 === 0,
  updated: new Date(2026, id % 12, (id % 27) + 1),
}));

export default class InMemoryTableDemo extends Component {
  @tracked selected = [];

  repos = REPOS;

  columns = [
    { field: 'name', name: 'Name', sortable: true },
    { field: 'language', name: 'Language', sortable: true },
    { field: 'stars', name: 'Stars', dataType: 'number', sortable: true },
    { field: 'archived', name: 'Archived', dataType: 'boolean' },
    { field: 'updated', name: 'Updated', dataType: 'date', sortable: true },
  ];

  search = {
    box: { incremental: true, schema: true },
    filters: [
      { type: 'is', field: 'archived', name: 'Archived', negatedName: 'Active' },
      {
        type: 'field_value_selection',
        field: 'language',
        name: 'Language',
        multiSelect: 'or',
        options: LANGUAGES.map((value) => ({ value })),
      },
    ],
  };

  sorting = { sort: { field: 'stars', direction: 'desc' } };

  pagination = { initialPageSize: 5, pageSizeOptions: [5, 10, 0] };

  selection = { onSelectionChange: (selected) => (this.selected = selected) };
}
```
