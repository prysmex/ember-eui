---
order: 2
---

# Editable cells

<EuiText>

Expand a cell (hover it and click the blue expand button, or focus it and
press Enter) to edit its value in the popover. Saving updates the data,
closes the popover through `@registerApi` and returns focus to the cell.
The "ID" column is read only (`isExpandable: false`).

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="Editable cells demo"
  @columns={{this.columns}}
  @rowCount={{this.rows.length}}
  @toolbarVisibility={{false}}
  @registerApi={{this.registerApi}}
>
  <:cell as |cell|>{{get (get this.rows cell.rowIndex) cell.columnId}}</:cell>
  <:cellPopover as |popover|>
    <form {{on "submit" (fn this.save popover.rowIndex popover.colIndex popover.columnId)}}>
      <EuiFormRow @label={{get this.labels popover.columnId}} @display="rowCompressed">
        <EuiFieldText
          @compressed={{true}}
          @value={{get (get this.rows popover.rowIndex) popover.columnId}}
          name="value"
          data-test-subj="editCellInput"
        />
      </EuiFormRow>
      <EuiSpacer @size="s" />
      <EuiFlexGroup @gutterSize="s" @justifyContent="flexEnd" @responsive={{false}}>
        <EuiButtonEmpty @size="s" {{on "click" (fn this.cancel popover.rowIndex popover.colIndex)}}>
          Cancel
        </EuiButtonEmpty>
        <EuiButton @size="s" @fill={{true}} @type="submit">Save</EuiButton>
      </EuiFlexGroup>
    </form>
  </:cellPopover>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class EditableCellsDemo extends Component {
  api = null;

  columns = [
    { id: 'id', displayAsText: 'ID', isExpandable: false, initialWidth: 70 },
    { id: 'name', displayAsText: 'Name' },
    { id: 'email', displayAsText: 'Email' },
    { id: 'role', displayAsText: 'Role' }
  ];

  labels = { name: 'Name', email: 'Email', role: 'Role' };

  @tracked rows = [
    { id: '1', name: 'Ada Lovelace', email: 'ada@example.com', role: 'Admin' },
    { id: '2', name: 'Grace Hopper', email: 'grace@example.com', role: 'Editor' },
    { id: '3', name: 'Alan Turing', email: 'alan@example.com', role: 'Viewer' },
    { id: '4', name: 'Katherine Johnson', email: 'katherine@example.com', role: 'Editor' }
  ];

  registerApi = (api) => {
    this.api = api;
  };

  @action save(rowIndex, colIndex, columnId, event) {
    event.preventDefault();
    const value = new FormData(event.target).get('value');
    this.rows = this.rows.map((row, i) => (i === rowIndex ? { ...row, [columnId]: value } : row));
    this.cancel(rowIndex, colIndex);
  }

  @action cancel(rowIndex, colIndex) {
    this.api?.closeCellPopover();
    this.api?.setFocusedCell({ rowIndex, colIndex });
  }
}
```
