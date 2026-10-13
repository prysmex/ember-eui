---
order: 6
---

# Adjusting your grid to user/toolbar changes

<EuiText>

You can use the optional `gridStyle.onChange` and `rowHeightsOptions.onChange`
callbacks to adjust your data grid based on user density or row height
changes.

For example, if the user changes the grid density to compressed, you may
want to adjust a cell's content sizing in response. Or you could store user
settings in localStorage or other database to preserve display settings on
page refresh, like the below example does.

</EuiText>

```hbs template
<EuiDataGrid
  aria-label="DataGrid demonstrating display selector callbacks"
  @leadingControlColumns={{this.leadingControlColumns}}
  @rowHeightsOptions={{this.rowHeightsOptions}}
  @gridStyle={{this.gridStyle}}
  @columns={{this.columns}}
  @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
  @rowCount={{this.data.length}}
>
  <:cell as |cell|>{{get (get this.data cell.rowIndex) cell.columnId}}</:cell>
  <:controlHeaderCell><EuiIcon @type="user" @size={{this.iconSize}} /></:controlHeaderCell>
  <:controlCell><EuiIcon @type="user" @size={{this.iconSize}} /></:controlCell>
</EuiDataGrid>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const data = [
  ['Kertzmann, Lorenzo Jr.', 'lorenzo.kertzmann@example.com', 'Port Isom', 'Portugal', '43172691'],
  ['Hessel, Adela DVM', 'adela_hessel@example.org', 'Lake Kianfort', 'Kenya', '08812395'],
  ['Bauch, Celestino III', 'celestino.bauch@example.net', 'Fort Gilberto', 'Chile', '91254066'],
  ['Wiza, Marlene PhD', 'marlene.wiza@example.com', 'New Teagan', 'Norway', '37020518'],
  ['Okuneva, Dario Sr.', 'dario_okuneva@example.org', 'West Mabel', 'Japan', '64409837']
].map(([name, email, city, country, account]) => ({ name, email, city, country, account }));

const GRID_STYLES_KEY = 'euiDataGridStyles';
const INITIAL_STYLES = JSON.stringify({ stripes: true });

const ROW_HEIGHTS_KEY = 'euiDataGridRowHeightsOptions';
const INITIAL_ROW_HEIGHTS = JSON.stringify({});

function read(key, initial) {
  try {
    return JSON.parse(localStorage.getItem(key) || initial);
  } catch {
    return JSON.parse(initial);
  }
}

function write(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    // storage unavailable (private mode): keep the change for this page only
  }
}

export default class DisplaySelectorCallbacksDemo extends Component {
  data = data;

  columns = [{ id: 'name' }, { id: 'email' }, { id: 'city' }, { id: 'country' }, { id: 'account' }];

  @tracked visibleColumns = this.columns.map(({ id }) => id);

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  // a control column whose icon follows the density
  @tracked densitySize = '';

  get iconSize() {
    return this.densitySize || 'm';
  }

  get leadingControlColumns() {
    let width = 32;
    if (this.densitySize === 'l') width = 44;
    if (this.densitySize === 's') width = 24;
    return [{ id: 'icon', width }];
  }

  // read once: the grid keeps the user's changes until new options are passed
  rowHeightsOptions = {
    ...read(ROW_HEIGHTS_KEY, INITIAL_ROW_HEIGHTS),
    onChange: (updatedRowHeights) => write(ROW_HEIGHTS_KEY, updatedRowHeights)
  };

  gridStyle = {
    ...read(GRID_STYLES_KEY, INITIAL_STYLES),
    onChange: (updatedStyles) => {
      write(GRID_STYLES_KEY, updatedStyles);
      this.densitySize = updatedStyles.fontSize;
    }
  };
}
```
