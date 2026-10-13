---
order: 2
---

# Visible cell actions and cell popovers

<EuiText>

By default, only the first 2 cell actions of a cell are displayed to the
left of the expand action button, and remaining actions are displayed in
the footer of the cell expansion popover.

This number is configurable by setting `columns.visibleCellActions`, should
you need to display more cell actions immediately. However, we advise
caution when increasing this limit: the default is set to ensure cell
action buttons do not crowd out content.

The below example shows an increasing number of `cellActions` in each
column. The third column shows `visibleCellActions` set to 3, and the
fourth column shows excess actions overflowing into the popover.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { get, hash } from '@ember/helper';
import { EuiDataGrid } from '@ember-eui/core/components';

const AddToTimeline = <template>
  <@Component @iconType="timeline">Add to timeline</@Component>
</template>;
const FilterIn = <template>
  <@Component @iconType="plusCircle" aria-label="Filter in">Filter in</@Component>
</template>;
const FilterOut = <template>
  <@Component @iconType="minusCircle" aria-label="Filter out">Filter out</@Component>
</template>;
const CustomAction1 = <template>
  <@Component @iconType="star">Custom action 1</@Component>
</template>;
const CustomAction2 = <template>
  <@Component @iconType="star">Custom action 2</@Component>
</template>;

const cellActions1 = [AddToTimeline];
const cellActions2 = [FilterIn, FilterOut];
const cellActions3 = [...cellActions2, ...cellActions1];
const cellActions5 = [...cellActions3, CustomAction1, CustomAction2];

const columns = [
  { id: 'default', cellActions: cellActions1 },
  { id: 'datetime', cellActions: cellActions2 },
  { id: 'json', schema: 'json', cellActions: cellActions3, visibleCellActions: 3 },
  { id: 'custom', schema: 'favoriteFranchise', cellActions: cellActions5 }
];

const data = [
  ['Hartmann, Ada Jr.', 'Tue Mar 12 2024 10:41:07 GMT+0000', '20375816', '412.08', 'Wed Aug 07 2024 16:02:55 GMT+0000'],
  ['Okafor, Bruno III', 'Sat Nov 30 2024 07:15:42 GMT+0000', '61049273', '87.50', 'Mon Jan 22 2024 21:30:19 GMT+0000'],
  ['Lindqvist, Carmen Sr.', 'Thu Jun 20 2024 23:58:01 GMT+0000', '87512046', '953.71', 'Fri Oct 04 2024 05:47:33 GMT+0000'],
  ['Moreau, Dmitri IV', 'Sun Feb 04 2024 13:26:50 GMT+0000', '39268105', '230.44', 'Tue Dec 17 2024 09:11:28 GMT+0000']
].map(([name, datetime, numeric, currency, date], i) => ({
  default: name,
  datetime,
  json: JSON.stringify([{ numeric, currency, date }]),
  custom: (i + 1) % 2 === 0 ? 'Star Wars' : 'Star Trek'
}));

export default class VisibleCellActionsDemo extends Component {
  @tracked visibleColumns = columns.map(({ id }) => id);

  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);

  <template>
    <EuiDataGrid
      aria-label="Data grid example of cellActions within popovers"
      @columns={{columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{data.length}}
    >
      <:cell as |cell|>{{get (get data cell.rowIndex) cell.columnId}}</:cell>
    </EuiDataGrid>
  </template>
}
```
