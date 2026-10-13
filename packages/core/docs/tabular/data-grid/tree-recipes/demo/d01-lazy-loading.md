---
order: 1
---

# Lazy loading children

<EuiText>

Every folder starts without children (`hasChildren: true`). Expanding one
shows a "Loading…" row for a moment, then the loaded children, which can
be folders themselves.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Lazy loading"
  @columns={{this.columns}}
  @rowTree={{hash rows=this.rows onExpandedChange=this.onExpandedChange}}
  @height={{320}}
>
  <:cell as |cell|>
    {{#if cell.row.isPlaceholder}}
      {{#if (eq cell.columnId "name")}}<EuiLoadingSpinner @size="s" /> Loading…{{/if}}
    {{else}}
      {{get cell.row cell.columnId}}
    {{/if}}
  </:cell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const folder = (path) => ({ id: path, name: path.split('/').pop(), kind: 'folder', hasChildren: true });

// stand-in for a server call
function fetchChildren(path) {
  return new Promise((resolve) =>
    setTimeout(
      () =>
        resolve([
          folder(`${path}/docs`),
          { id: `${path}/a.txt`, name: 'a.txt', kind: 'file' },
          { id: `${path}/b.txt`, name: 'b.txt', kind: 'file' }
        ]),
      700
    )
  );
}

// returns new arrays down to the replaced row
function replaceRow(rows, id, update) {
  return rows.map((row) => {
    if (row.id === id) return update(row);
    if (row.children) return { ...row, children: replaceRow(row.children, id, update) };
    return row;
  });
}

export default class LazyLoadingDemo extends Component {
  @tracked rows = [folder('home'), folder('work'), { id: 'notes.txt', name: 'notes.txt', kind: 'file' }];
  requested = new Set();

  columns = [
    { id: 'name', displayAsText: 'Name', initialWidth: 300 },
    { id: 'kind', displayAsText: 'Kind' }
  ];

  @action onExpandedChange(ids) {
    for (const id of ids) {
      if (this.requested.has(id)) continue;
      this.requested.add(id);
      this.rows = replaceRow(this.rows, id, (row) => ({
        ...row,
        children: [{ id: `${id}/…`, isPlaceholder: true }]
      }));
      fetchChildren(id).then((children) => {
        if (this.isDestroyed) return;
        this.rows = replaceRow(this.rows, id, (row) => ({ ...row, children }));
      });
    }
  }
}
```
