---
order: 2
---

# Row order and colours

<EuiText>

With `@canMove` each row number has a grip: drag it to put the record
somewhere else, or press Alt+Shift+ArrowUp / ArrowDown on a row number.
Checked rows (or a range of whole rows) move together. The sheet moves
nothing itself: `@onChange` gets a change set with `moves`, and
`localRecords` applies it; Ctrl+Z puts the rows back. A `@sort` turns
the grip off (the order is then the sort's).

Group by Status and drag a record into another group: the same change
set also writes its Status. A drop on a collapsed group's header puts
it in that group. Each row has a bar in its status's colour:
`@rowColor={{colorByOption statusField}}` reads the option's `color`.
The first field is frozen, so on a narrow screen the bar and the task
stay in view while the other columns scroll.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiFlexGroup, EuiFlexItem, EuiSwitch, EuiText } from '@ember-eui/core/components';
import { EuiSheet, colorByOption, localRecords } from '@ember-eui/sheet';

const STATUS = {
  id: 'status',
  label: 'Status',
  type: 'singleSelect',
  width: 140,
  options: [
    { value: 'todo', label: 'To do', color: 'default' },
    { value: 'doing', label: 'Doing', color: 'primary' },
    { value: 'blocked', label: 'Blocked', color: 'danger' },
    { value: 'done', label: 'Done', color: 'success' },
  ],
};

const FIELDS = [
  { id: 'name', label: 'Task', required: true, width: 220 },
  STATUS,
  { id: 'owner', label: 'Owner', width: 140 },
];

const NAMES = [
  'Write the brief', 'Book the venue', 'Order the badges', 'Call the caterer',
  'Print the menus', 'Test the sound', 'Send the invites', 'Plan the seating',
  'Pick the music', 'Pay the deposit',
];
const STATUSES = ['todo', 'doing', 'blocked', 'done', 'doing', 'todo', 'done', 'todo', 'blocked', 'doing'];

const RECORDS = NAMES.map((name, i) => ({
  id: `t${i + 1}`,
  name,
  status: STATUSES[i],
  owner: ['Ana', 'Bruno', 'Carla'][i % 3],
}));

export default class SheetRowOrder extends Component {
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId, fields: FIELDS });
  rowColor = colorByOption(STATUS);
  @tracked moves = 0;

  get grouped() {
    return this.store.groupBy.length > 0;
  }

  toggleGrouped = (event) => {
    this.store.setGroupBy(event.target.checked ? [{ field: 'status', direction: 'asc' }] : []);
  };

  onChange = (changeSet) => {
    if (changeSet.moves?.length) this.moves += 1;
    this.store.apply(changeSet);
  };

  get order() {
    return this.store.records.map((record) => record.id).join(' ');
  }

  <template>
    <EuiSheet
      @fields={{this.store.fields}}
      @records={{this.store.view.records}}
      @groups={{this.store.view.groups}}
      @groupBy={{this.store.groupBy}}
      @onGroupByChange={{this.store.setGroupBy}}
      @onGroupToggle={{this.store.toggleGroup}}
      @getRecordId={{this.getId}}
      @onChange={{this.onChange}}
      @canMove={{true}}
      @rowColor={{this.rowColor}}
      @frozenFields={{1}}
      @height={{420}}
      @ariaLabel='Tasks'
    >
      <:toolbar>
        <EuiFlexGroup @gutterSize='m' @alignItems='center' @responsive={{false}}>
          <EuiFlexItem @grow={{false}}>
            <EuiSwitch
              @label='Group by status'
              @checked={{this.grouped}}
              @compressed={{true}}
              @onChange={{this.toggleGrouped}}
            />
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiText @size='xs' @color='subdued' data-test-subj='rowOrder'>
              Moves: {{this.moves}}. Store order: {{this.order}}
            </EuiText>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:toolbar>
    </EuiSheet>
  </template>
}
```

<EuiText>

An owner with its own store applies `moves` in order: take the record
out and put it back before or after `anchor.recordId`; a move without an
anchor (into an empty or collapsed group) only changes its group, which
its patches already wrote. A backend keeps the order in a column of its
own (an integer, or fractional positions so a move writes one record).
Paged data: anchors are record ids, as with inserts, so a move never
needs the page's offset.

</EuiText>
