---
order: 2
---

# Grid row classes

<EuiText>

Specific rows can be highlighted or otherwise have custom styling passed to
them via the `gridStyle.rowClasses` option. It accepts an object associating
the row's index with a class name string.

The example below sets a custom striped class on the 3rd row and dynamically
updates the `rowClasses` map when rows are selected. The selected row style
is passed with the grid's `@css` argument, using the theme from
`getEuiThemeContext`.

<EuiCallOut @title="There are styling utility classes available: euiDataGridRow--marked and euiDataGridRow--selected" @size="s">
  <p>
    These classes can be useful to highlight rows either as selected or
    marked (highlighted). Use the <code>gridStyle.rowClasses</code> option to
    add the classes to specific rows. Both utility classes additionally
    define hover styles when <code>rowHover</code> equals
    <code>highlight</code>.
  </p>
</EuiCallOut>

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { getEuiThemeContext } from '@ember-eui/core/utils/emotion/consume';
import { concat, fn, get, hash } from '@ember/helper';
import { on } from '@ember/modifier';
import { EuiButtonEmpty, EuiCheckbox, EuiDataGrid } from '@ember-eui/core/components';

const data = [
  ['Kertzmann, Lorenzo Jr.', 'lorenzo.kertzmann@example.com', 'Port Isom', 'Portugal', '43172691'],
  ['Hessel, Adela DVM', 'adela_hessel@example.org', 'Lake Kianfort', 'Kenya', '08812395'],
  ['Bauch, Celestino III', 'celestino.bauch@example.net', 'Fort Gilberto', 'Chile', '91254066'],
  ['Wiza, Marlene PhD', 'marlene.wiza@example.com', 'New Teagan', 'Norway', '37020518'],
  ['Okuneva, Dario Sr.', 'dario_okuneva@example.org', 'West Mabel', 'Japan', '64409837']
].map(([name, email, city, country, account]) => ({ name, email, city, country, account }));

const MARKED_ROW = 2;
const SELECTED_ROW = 3;
data[MARKED_ROW].account = 'OVERDUE';

export default class GridRowClassesDemo extends Component {
  data = data;

  columns = [{ id: 'name' }, { id: 'email' }, { id: 'city' }, { id: 'country' }, { id: 'account' }];

  leadingControlColumns = [{ id: 'selection', width: 32 }];

  @tracked visibleColumns = this.columns.map(({ id }) => id);

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  // selection
  @tracked selectedRows = new Set([1]);

  get hasSelection() {
    return this.selectedRows.size > 0;
  }

  get hasMany() {
    return this.selectedRows.size > 1;
  }

  get isIndeterminate() {
    return this.selectedRows.size > 0 && this.selectedRows.size < data.length;
  }

  isSelected = (rowIndex) => this.selectedRows.has(rowIndex);

  @action toggleRow(rowIndex, event) {
    const next = new Set(this.selectedRows);
    if (event.target.checked) next.add(rowIndex);
    else next.delete(rowIndex);
    this.selectedRows = next;
  }

  @action toggleAll(event) {
    // an indeterminate checkbox clears the selection
    this.selectedRows =
      !this.isIndeterminate && event.target.checked
        ? new Set(data.map((_, index) => index))
        : new Set();
  }

  @action notARealControl() {
    window.alert('This is not a real control.');
  }

  // styles
  get rowStyles() {
    const { euiTheme } = getEuiThemeContext(this).upstream;
    return {
      '.euiDataGridRow--rowClassesDemoSelected': {
        backgroundColor: euiTheme.colors.backgroundBaseInteractiveSelect,
        '&:hover': {
          backgroundColor: euiTheme.colors.backgroundBaseInteractiveSelectHover
        }
      }
    };
  }

  get gridStyle() {
    const rowClasses = {
      [MARKED_ROW]: 'euiDataGridRow--marked',
      [SELECTED_ROW]: 'euiDataGridRow--selected'
    };
    this.selectedRows.forEach((rowIndex) => {
      rowClasses[rowIndex] = 'euiDataGridRow--rowClassesDemoSelected';
    });
    return { rowClasses };
  }

  <template>
    <EuiDataGrid
      aria-label="Top EUI contributors"
      @columns={{this.columns}}
      @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
      @rowCount={{this.data.length}}
      @leadingControlColumns={{this.leadingControlColumns}}
      @gridStyle={{this.gridStyle}}
      @css={{this.rowStyles}}
    >
      <:cell as |cell|>{{get (get this.data cell.rowIndex) cell.columnId}}</:cell>
      <:controlHeaderCell>
        <EuiCheckbox
          @id="selection-toggle"
          aria-label="Select all rows"
          @indeterminate={{this.isIndeterminate}}
          @checked={{this.hasSelection}}
          {{on "change" this.toggleAll}}
        />
      </:controlHeaderCell>
      <:controlCell as |cell|>
        <EuiCheckbox
          @id={{concat "row-classes-" cell.rowIndex}}
          aria-label={{concat "Select row " cell.rowIndex ", " (get (get this.data cell.rowIndex) "name")}}
          @checked={{this.isSelected cell.rowIndex}}
          {{on "change" (fn this.toggleRow cell.rowIndex)}}
        />
      </:controlCell>
      <:leftControlsAppend>
        {{#if this.hasSelection}}
          <EuiButtonEmpty
            @size="xs"
            @iconType="chevronSingleDown"
            @iconSide="right"
            {{on "click" this.notARealControl}}
          >
            {{this.selectedRows.size}} {{if this.hasMany "items" "item"}} selected
          </EuiButtonEmpty>
        {{/if}}
      </:leftControlsAppend>
    </EuiDataGrid>
  </template>
}
```
