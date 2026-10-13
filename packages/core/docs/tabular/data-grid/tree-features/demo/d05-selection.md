---
order: 5
---

# Selection with a control column

<EuiText>

A leading control column with checkboxes. Selecting a folder selects
everything below it. The demo walks `row.children`, since selection is the
consumer's state.

</EuiText>

```hbs template
<EuiText @size="s"><p>{{this.selectedCount}} selected</p></EuiText>
<EuiSpacer @size="s" />
<EuiDataGrid
  aria-label="Selection"
  @columns={{this.columns}}
  @rowTree={{hash rows=this.files defaultExpandedRowIds="all"}}
  @leadingControlColumns={{this.leading}}
  @toolbarVisibility={{false}}
  @height={{300}}
>
  <:cell as |cell|>{{get cell.row cell.columnId}}</:cell>
  <:controlHeaderCell>
    <EuiScreenReaderOnly><span>Select</span></EuiScreenReaderOnly>
  </:controlHeaderCell>
  <:controlCell as |cell|>
    <EuiCheckbox
      aria-label="Select {{cell.row.name}}"
      @checked={{this.isSelected cell.row}}
      {{on "change" (fn this.toggle cell.row)}}
    />
  </:controlCell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const descendants = (row) => [row, ...(row.children ?? []).flatMap(descendants)];

export default class SelectionDemo extends Component {
  @tracked selected = new Set();

  leading = [{ id: 'select', width: 36 }];

  columns = [
    { id: 'name', displayAsText: 'Name' },
    { id: 'size', displayAsText: 'Size (KB)', schema: 'numeric' }
  ];

  files = [
    {
      id: 'src',
      name: 'src',
      size: 30,
      children: [
        { id: 'app', name: 'app.ts', size: 20 },
        { id: 'utils', name: 'utils', size: 10, children: [{ id: 'keys', name: 'keys.ts', size: 10 }] }
      ]
    },
    { id: 'readme', name: 'README.md', size: 5 }
  ];

  get selectedCount() {
    return this.selected.size;
  }

  isSelected = (row) => this.selected.has(row.id);

  @action toggle(row) {
    const next = new Set(this.selected);
    const select = !next.has(row.id);
    for (const item of descendants(row)) {
      if (select) next.add(item.id);
      else next.delete(item.id);
    }
    this.selected = next;
  }
}
```
