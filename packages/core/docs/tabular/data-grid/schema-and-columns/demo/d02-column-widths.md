---
order: 2
---

# Column widths

<EuiText>

By default, visible columns are given equal widths to fill up available
space in the grid and can be resized by the user to any desired width.
There are two parameters on **EuiDataGridColumn** to change this default
behavior. `initialWidth` is a numeric value providing the starting width of
a column, in pixels. Second, the `isResizable` value can be set to `false`
to remove the user's ability to resize column.

Below, the first column is given an initial width and is not resizable. The
second column is also given an initial width but its width can still be
changed.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import { EuiAvatar, EuiDataGrid } from '@ember-eui/core/components';

const LAST = ['Schmidt', 'Okafor', 'Lindqvist', 'Moreau', 'Tanaka', 'Novak', 'Ferreira', 'Kowalski', 'Haddad'];
const FIRST = ['Amara', 'Bruno', 'Chloe', 'Dmitri', 'Elena', 'Felix', 'Grace', 'Hiro', 'Ines', 'Jonas', 'Keira'];
const SUFFIXES = ['Jr.', 'Sr.', 'II', 'III', 'MD', 'PhD', 'DVM'];
const CITIES = ['Lake Ottoport', 'North Kaleigh', 'East Damian', 'Port Ellis', 'New Brayden', 'West Coraline'];
const COUNTRIES = ['Portugal', 'Norway', 'Japan', 'Peru', 'Kenya', 'Canada', 'Iceland', 'Chile'];

const data = Array.from({ length: 4 }, (_, i) => ({
  avatar: `${LAST[(i * 4 + 2) % LAST.length]}, ${FIRST[(i * 5 + 1) % FIRST.length]}`,
  name: `${LAST[i % LAST.length]}, ${FIRST[(i * 7) % FIRST.length]} ${SUFFIXES[i % SUFFIXES.length]}`,
  email: `${FIRST[(i * 7) % FIRST.length]}.${LAST[i % LAST.length]}${i}@example.com`.toLowerCase(),
  city: CITIES[(i * 5) % CITIES.length],
  country: COUNTRIES[(i * 3) % COUNTRIES.length],
  account: String(10000000 + ((i * 7919 * 104729) % 89999999))
}));

const columns = [
  { id: 'avatar', initialWidth: 40, isResizable: false },
  { id: 'name', initialWidth: 100 },
  { id: 'email' },
  { id: 'city' },
  { id: 'country' },
  { id: 'account' }
];

export default class ColumnsDemo extends Component {
  data = data;
  columns = columns;
  @tracked visibleColumns = columns.map(({ id }) => id);
  @tracked pageIndex = 0;
  @tracked pageSize;

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  @action setPageIndex(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action setPageSize(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }

  <template>
    <EuiDataGrid
      aria-label="DataGrid demonstrating column sizing constraints"
      @columns={{this.columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{this.data.length}}
      @pagination={{hash
        pageIndex=this.pageIndex
        pageSize=this.pageSize
        onChangeItemsPerPage=this.setPageSize
        onChangePage=this.setPageIndex
      }}
    >
      <:cell as |cell|>
        {{#if (eq cell.columnId "avatar")}}
          <EuiAvatar @size="s" @name={{get (get this.data cell.rowIndex) "avatar"}} />
        {{else}}
          {{get (get this.data cell.rowIndex) cell.columnId}}
        {{/if}}
      </:cell>
    </EuiDataGrid>
  </template>
}
```
