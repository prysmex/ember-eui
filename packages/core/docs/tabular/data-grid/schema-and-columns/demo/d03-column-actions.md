---
order: 3
---

# Column actions

<EuiText>

By default, columns provide actions for sorting, moving and hiding. These
can be extended with custom actions. You can customize the actions by
setting the `actions` value of **EuiDataGridColumn**. Setting it to `false`
removes the action menu displayed. You can configure it by passing an object
of type **EuiDataGridColumnAction**. This allows you to hide, configure the
existing actions and add new ones.

Below, the first column provides no action, the second doesn't provide the
ability to hide the columns, the 3rd provides an additional action, the 4th
overwrites the hide action with a custom label and icon.

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
  { id: 'avatar', initialWidth: 40, isResizable: false, actions: false },
  { id: 'name', initialWidth: 100, isSortable: true, actions: { showHide: false } },
  {
    id: 'email',
    isSortable: true,
    actions: {
      additional: [{ iconType: 'heart', label: 'Send Email', size: 'xs', onClick: () => {} }]
    }
  },
  {
    id: 'city',
    isSortable: true,
    actions: { showHide: { iconType: 'cross', label: 'Remove column' } }
  },
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
