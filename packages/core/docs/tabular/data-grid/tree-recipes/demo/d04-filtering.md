---
order: 4
---

# Filtering a tree

<EuiText>

Type to filter (try "test" or "button"). Matching rows stay in place
under their ancestors, which start expanded. Clear the search to restore
the expansion you had before searching.

</EuiText>

```hbs template
<EuiFieldSearch
  @value={{this.query}}
  @onSearch={{this.search}}
  @incremental={{true}}
  @isClearable={{true}}
  placeholder="Filter files"
  aria-label="Filter files"
/>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Filtered tree"
  @columns={{this.columns}}
  @rowTree={{hash
    rows=this.filtered.rows
    expandedRowIds=this.expandedRowIds
    onExpandedChange=this.onExpandedChange
  }}
  @height={{320}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked, cached } from '@glimmer/tracking';
import { action } from '@ember/object';

const FILES = [
  {
    id: 'src',
    name: 'src',
    children: [
      {
        id: 'src/components',
        name: 'components',
        children: [
          { id: 'src/components/button.gts', name: 'button.gts' },
          { id: 'src/components/data-grid.gts', name: 'data-grid.gts' }
        ]
      },
      { id: 'src/utils', name: 'utils', children: [{ id: 'src/utils/keys.ts', name: 'keys.ts' }] }
    ]
  },
  {
    id: 'tests',
    name: 'tests',
    children: [
      { id: 'tests/button-test.gts', name: 'button-test.gts' },
      { id: 'tests/data-grid-test.gts', name: 'data-grid-test.gts' }
    ]
  },
  { id: 'README.md', name: 'README.md' }
];

/** Keeps matching rows and their ancestors; returns the kept tree and the ancestor ids. */
function filterTree(rows, matches) {
  const ancestors = [];
  const visit = (items) =>
    items.flatMap((row) => {
      const children = row.children ? visit(row.children) : [];
      if (children.length) {
        ancestors.push(row.id);
        return [{ ...row, children }];
      }
      return matches(row) ? [{ ...row, children: undefined }] : [];
    });
  return { rows: visit(rows), ancestors };
}

export default class FilteringDemo extends Component {
  @tracked query = '';
  @tracked browsingIds = ['src'];

  columns = [{ id: 'name', displayAsText: 'Name' }];

  @cached
  get filtered() {
    const query = this.query.trim().toLowerCase();
    if (!query) return { rows: FILES, ancestors: [] };
    return filterTree(FILES, (row) => row.name.toLowerCase().includes(query));
  }

  // expansion while searching starts from the matches' ancestors
  @tracked searchingIds = null;

  get expandedRowIds() {
    if (!this.query.trim()) return this.browsingIds;
    return this.searchingIds ?? this.filtered.ancestors;
  }

  @action search(query) {
    this.query = query;
    this.searchingIds = null;
  }

  @action onExpandedChange(ids) {
    if (this.query.trim()) this.searchingIds = ids;
    else this.browsingIds = ids;
  }
}
```
